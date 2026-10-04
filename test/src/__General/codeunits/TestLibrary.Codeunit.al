namespace CommerceConnector.Test;

using CommerceConnector.Events;
using CommerceConnector.General;
using CommerceConnector.Orders;
using CommerceConnector.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

codeunit 74000 "CMC Test Library"
{
    Access = Public;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";

    /// <summary>
    /// Puts the session back on the shipped implementations. The service locator is single instance, so a fake
    /// injected by one test would otherwise survive into the next one, and into every other app's tests.
    /// </summary>
    procedure RestoreDefaultImplementations()
    var
        CommerceReactions: Codeunit "CMC Commerce Reactions";
        OrderIntake: Codeunit "CMC Order Intake";
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        ServiceLocator.ImplementReactions(CommerceReactions);
        ServiceLocator.ImplementOrderIntake(OrderIntake);
    end;

    /// <summary>
    /// Replaces the setup record with one carrying the shipped defaults.
    /// </summary>
    procedure ResetSetup()
    var
        CommerceSetup: Record "CMC Commerce Setup";
    begin
        CommerceSetup.DeleteAll();
        CommerceSetup.GetSetup();
    end;

    /// <summary>
    /// Switches recording of catalogue changes on the outbox on or off.
    /// </summary>
    /// <param name="Enable">Whether changes are recorded.</param>
    procedure SetPublishBusinessEvents(Enable: Boolean)
    var
        CommerceSetup: Record "CMC Commerce Setup";
    begin
        CommerceSetup.GetSetup();
        CommerceSetup."Publish Business Events" := Enable;
        CommerceSetup.Modify();
    end;

    /// <summary>
    /// Sets the order intake retry policy.
    /// </summary>
    /// <param name="MaxAttempts">Attempts before a staged order is abandoned.</param>
    /// <param name="BackoffSeconds">Base retry delay, doubled per attempt.</param>
    procedure SetRetryPolicy(MaxAttempts: Integer; BackoffSeconds: Integer)
    var
        CommerceSetup: Record "CMC Commerce Setup";
    begin
        CommerceSetup.GetSetup();
        CommerceSetup."Order Intake Max Attempts" := MaxAttempts;
        CommerceSetup."Retry Backoff Seconds" := BackoffSeconds;
        CommerceSetup.Modify();
    end;

    /// <summary>
    /// Turns off the stockout and credit warnings so creating a sales line raises no notification.
    /// </summary>
    procedure DisableSalesWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Stockout Warning" := false;
        SalesReceivablesSetup."Credit Warnings" := SalesReceivablesSetup."Credit Warnings"::"No Warning";
        SalesReceivablesSetup.Modify();
    end;

    /// <summary>
    /// Removes every staged order and line, so a test sees only the rows it creates.
    /// </summary>
    procedure DeleteAllStaging()
    var
        OrderStaging: Record "CMC Order Staging";
        OrderStagingLine: Record "CMC Order Staging Line";
    begin
        OrderStagingLine.DeleteAll();
        OrderStaging.DeleteAll();
    end;

    /// <summary>
    /// Removes every outbox entry, so a test sees only the entries it causes.
    /// </summary>
    procedure DeleteAllOutbox()
    var
        ChangeOutbox: Record "CMC Change Outbox";
    begin
        ChangeOutbox.DeleteAll();
    end;

    /// <summary>
    /// Creates a customer through the standard test library.
    /// </summary>
    procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    /// <summary>
    /// Creates an item with a known list price.
    /// </summary>
    /// <param name="UnitPrice">The item's unit price.</param>
    procedure CreateItemNo(UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item.Modify(true);
        exit(Item."No.");
    end;

    /// <summary>
    /// Adds an alternative unit of measure to an item.
    /// </summary>
    /// <param name="ItemNo">The item.</param>
    /// <param name="QtyPerUnitOfMeasure">How many base units the new unit holds.</param>
    procedure AddItemUnitOfMeasure(ItemNo: Code[20]; QtyPerUnitOfMeasure: Decimal): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, QtyPerUnitOfMeasure);
        exit(ItemUnitOfMeasure.Code);
    end;

    /// <summary>
    /// Sets the sales unit of measure of an item.
    /// </summary>
    /// <param name="ItemNo">The item.</param>
    /// <param name="UnitOfMeasureCode">The unit sales documents default to.</param>
    procedure SetItemSalesUnitOfMeasure(ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Sales Unit of Measure", UnitOfMeasureCode);
        Item.Modify(true);
    end;

    /// <summary>
    /// Sets the unit of measure on a staged line.
    /// </summary>
    /// <param name="OrderStaging">The staged order.</param>
    /// <param name="LineNo">The staging line number.</param>
    /// <param name="UnitOfMeasureCode">The unit the line's quantity is expressed in.</param>
    procedure SetStagedLineUnitOfMeasure(var OrderStaging: Record "CMC Order Staging"; LineNo: Integer; UnitOfMeasureCode: Code[10])
    var
        OrderStagingLine: Record "CMC Order Staging Line";
    begin
        OrderStagingLine.Get(OrderStaging."Entry No.", LineNo);
        OrderStagingLine."Unit of Measure Code" := UnitOfMeasureCode;
        OrderStagingLine.Modify();
    end;

    /// <summary>
    /// Returns an idempotency key no other staged order carries.
    /// </summary>
    procedure NewIdempotencyKey(): Code[64]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 64));
    end;

    /// <summary>
    /// Stages an order header for the customer, through the insert trigger as the API page does.
    /// </summary>
    /// <param name="OrderStaging">Returns the staged order.</param>
    /// <param name="CustomerNo">The customer the order is for.</param>
    /// <param name="DocumentType">Whether the order becomes a sales order or a quote.</param>
    procedure CreateStagedOrder(var OrderStaging: Record "CMC Order Staging"; CustomerNo: Code[20]; DocumentType: Enum "CMC Commerce Document Type")
    begin
        OrderStaging.Init();
        OrderStaging."Idempotency Key" := NewIdempotencyKey();
        OrderStaging."Platform Order Id" := CopyStr(OrderStaging."Idempotency Key", 1, MaxStrLen(OrderStaging."Platform Order Id"));
        OrderStaging."External Reference" := CopyStr(OrderStaging."Idempotency Key", 1, 20);
        OrderStaging."Customer No." := CustomerNo;
        OrderStaging."Document Type" := DocumentType;
        OrderStaging.Insert(true);
    end;

    /// <summary>
    /// Adds a line to a staged order.
    /// </summary>
    /// <param name="OrderStaging">The staged order.</param>
    /// <param name="LineNo">The staging line number.</param>
    /// <param name="ItemNo">The item ordered.</param>
    /// <param name="Quantity">The quantity ordered.</param>
    /// <param name="AgreedUnitPrice">The price the shopper accepted; zero accepts whatever Business Central resolves.</param>
    procedure AddStagedLine(var OrderStaging: Record "CMC Order Staging"; LineNo: Integer; ItemNo: Code[20]; Quantity: Decimal; AgreedUnitPrice: Decimal)
    var
        OrderStagingLine: Record "CMC Order Staging Line";
    begin
        OrderStagingLine.Init();
        OrderStagingLine."Entry No." := OrderStaging."Entry No.";
        OrderStagingLine."Line No." := LineNo;
        OrderStagingLine."Line Ref" := CopyStr(Format(LineNo), 1, MaxStrLen(OrderStagingLine."Line Ref"));
        OrderStagingLine."Item No." := ItemNo;
        OrderStagingLine.Quantity := Quantity;
        OrderStagingLine."Agreed Unit Price" := AgreedUnitPrice;
        OrderStagingLine.Insert(true);
    end;

    /// <summary>
    /// Moves a staged order's retry time a minute into the past, so the queue sees it as due regardless of how the
    /// database rounds the time stamped on insert.
    /// </summary>
    /// <param name="OrderStaging">The staged order.</param>
    procedure MakeDue(var OrderStaging: Record "CMC Order Staging")
    begin
        OrderStaging.Get(OrderStaging."Entry No.");
        OrderStaging."Next Retry At" := CurrentDateTime() - 60000;
        OrderStaging.Modify();
    end;

    /// <summary>
    /// Stages a sales order for a new customer with one line for a new item priced at the agreed price.
    /// </summary>
    /// <param name="OrderStaging">Returns the staged order.</param>
    /// <param name="UnitPrice">The item's list price, which is also the agreed price on the line.</param>
    procedure CreateStagedOrderWithLine(var OrderStaging: Record "CMC Order Staging"; UnitPrice: Decimal)
    begin
        CreateStagedOrder(OrderStaging, CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        AddStagedLine(OrderStaging, 1, CreateItemNo(UnitPrice), 2, UnitPrice);
    end;
}
