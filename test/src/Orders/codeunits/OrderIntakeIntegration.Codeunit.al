namespace CommerceConnector.Test;

using CommerceConnector.General;
using CommerceConnector.Orders;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

codeunit 74005 "CMC Order Intake Integration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "CMC Test Library";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        PriceMismatchTok: Label 'but Business Central resolved', Locked = true;
        NoLinesTok: Label 'carries no lines', Locked = true;

    /// <summary>
    /// Given a staged order whose agreed price matches the item price, when it is processed, then a sales order
    /// is created for the customer with the staged line, and the staging row records the document and completes.
    /// </summary>
    [Test]
    procedure StagedOrderBecomesSalesOrder()
    var
        OrderStaging: Record "CMC Order Staging";
        OrderStagingLine: Record "CMC Order Staging Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrderWithLine(OrderStaging, 100);
        FindFirstLine(OrderStaging, OrderStagingLine);

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(OrderStaging.Status::Completed, OrderStaging.Status, 'Status');
        Assert.AreEqual(1, OrderStaging.Attempts, 'Attempts');
        Assert.AreEqual('', OrderStaging."Last Error", 'Last Error');
        Assert.AreNotEqual(0DT, OrderStaging."Completed At", 'Completed At');
        Assert.IsTrue(SalesHeader.Get(SalesHeader."Document Type"::Order, OrderStaging."Created Document No."), 'The created sales order must exist');
        Assert.AreEqual(OrderStaging."Customer No.", SalesHeader."Sell-to Customer No.", 'Sell-to Customer No.');
        Assert.AreEqual(OrderStaging."External Reference", SalesHeader."External Document No.", 'External Document No.');
        Assert.IsTrue(SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000), 'Staging line 1 must become sales line 10000');
        Assert.AreEqual(SalesLine.Type::Item, SalesLine.Type, 'Line type');
        Assert.AreEqual(OrderStagingLine."Item No.", SalesLine."No.", 'Item No.');
        Assert.AreEqual(2, SalesLine.Quantity, 'Quantity');
        Assert.AreEqual(100, SalesLine."Unit Price", 'Unit Price');
    end;

    /// <summary>
    /// Given a staged submission of document type Quote, when it is processed, then a sales quote is created.
    /// </summary>
    [Test]
    procedure QuoteSubmissionBecomesSalesQuote()
    var
        OrderStaging: Record "CMC Order Staging";
        SalesHeader: Record "Sales Header";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Quote);
        TestLibrary.AddStagedLine(OrderStaging, 1, TestLibrary.CreateItemNo(50), 1, 50);

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        Assert.IsTrue(SalesHeader.Get(SalesHeader."Document Type"::Quote, OrderStaging."Created Document No."), 'The created sales quote must exist');
    end;

    /// <summary>
    /// Given a staged order without an agreed price, when it is processed, then the price Business Central
    /// resolves is accepted.
    /// </summary>
    [Test]
    procedure MissingAgreedPriceAcceptsResolvedPrice()
    var
        OrderStaging: Record "CMC Order Staging";
        SalesLine: Record "Sales Line";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        TestLibrary.AddStagedLine(OrderStaging, 1, TestLibrary.CreateItemNo(75), 1, 0);

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        SalesLine.Get(SalesLine."Document Type"::Order, OrderStaging."Created Document No.", 10000);
        Assert.AreEqual(75, SalesLine."Unit Price", 'Unit Price');
    end;

    /// <summary>
    /// Given a staged order whose agreed price differs from the price Business Central resolves, when it is
    /// processed, then the submission is rejected rather than repriced, no sales document survives, and the row
    /// is scheduled for a retry with the mismatch as its error.
    /// </summary>
    [Test]
    procedure PriceMismatchIsRejectedWithoutDocument()
    var
        OrderStaging: Record "CMC Order Staging";
        SalesHeader: Record "Sales Header";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        TestLibrary.AddStagedLine(OrderStaging, 1, TestLibrary.CreateItemNo(100), 1, 90);

        Assert.IsFalse(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report failure');

        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(OrderStaging.Status::Pending, OrderStaging.Status, 'Status');
        Assert.AreEqual(1, OrderStaging.Attempts, 'Attempts');
        Assert.AreEqual('', OrderStaging."Created Document No.", 'Created Document No.');
        Assert.IsTrue(StrPos(OrderStaging."Last Error", PriceMismatchTok) > 0, 'Last Error must explain the price mismatch');
        Assert.IsTrue(OrderStaging."Next Retry At" > CurrentDateTime(), 'The retry must be scheduled in the future');
        SalesHeader.SetRange("Sell-to Customer No.", OrderStaging."Customer No.");
        Assert.IsTrue(SalesHeader.IsEmpty(), 'A rejected submission must not leave a sales document behind');
    end;

    /// <summary>
    /// Given a staged order without lines, when it is processed, then it fails with an explanation and no sales
    /// document survives.
    /// </summary>
    [Test]
    procedure OrderWithoutLinesFails()
    var
        OrderStaging: Record "CMC Order Staging";
        SalesHeader: Record "Sales Header";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);

        Assert.IsFalse(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report failure');

        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.IsTrue(StrPos(OrderStaging."Last Error", NoLinesTok) > 0, 'Last Error must say the order has no lines');
        SalesHeader.SetRange("Sell-to Customer No.", OrderStaging."Customer No.");
        Assert.IsTrue(SalesHeader.IsEmpty(), 'A failed submission must not leave a sales document behind');
    end;

    /// <summary>
    /// Given a staged order for a customer that does not exist, when it is processed, then the standard
    /// validation error is kept and the row is scheduled for a retry.
    /// </summary>
    [Test]
    procedure UnknownCustomerFailsAndSchedulesRetry()
    var
        OrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrder(OrderStaging, CopyStr(TestLibrary.NewIdempotencyKey(), 1, 20), Enum::"CMC Commerce Document Type"::Order);
        TestLibrary.AddStagedLine(OrderStaging, 1, TestLibrary.CreateItemNo(10), 1, 10);

        Assert.IsFalse(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report failure');

        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(OrderStaging.Status::Pending, OrderStaging.Status, 'Status');
        Assert.AreNotEqual('', OrderStaging."Last Error", 'Last Error');
    end;

    /// <summary>
    /// Given a retry policy of a single attempt, when the only attempt fails, then the row is abandoned.
    /// </summary>
    [Test]
    procedure ExhaustedAttemptsAbandonRow()
    var
        OrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.SetRetryPolicy(1, 60);
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        TestLibrary.AddStagedLine(OrderStaging, 1, TestLibrary.CreateItemNo(100), 1, 1);

        OrderIntake.ProcessOne(OrderStaging);

        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(OrderStaging.Status::Abandoned, OrderStaging.Status, 'Status');
    end;

    /// <summary>
    /// Given a staged order with a location and a requested delivery date, when it is processed, then both reach
    /// the sales header and the location reaches the line.
    /// </summary>
    [Test]
    procedure HeaderLocationAndDeliveryDatePropagate()
    var
        Location: Record Location;
        OrderStaging: Record "CMC Order Staging";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        OrderStaging."Location Code" := Location.Code;
        OrderStaging."Requested Delivery Date" := CalcDate('<+7D>', WorkDate());
        OrderStaging.Modify();
        TestLibrary.AddStagedLine(OrderStaging, 1, TestLibrary.CreateItemNo(20), 1, 20);

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderStaging."Created Document No.");
        Assert.AreEqual(Location.Code, SalesHeader."Location Code", 'Header Location Code');
        Assert.AreEqual(OrderStaging."Requested Delivery Date", SalesHeader."Requested Delivery Date", 'Requested Delivery Date');
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        Assert.AreEqual(Location.Code, SalesLine."Location Code", 'Line Location Code');
    end;

    /// <summary>
    /// Given a staged order with two lines, when it is processed, then each staging line becomes a sales line
    /// numbered ten thousand times its staging line number.
    /// </summary>
    [Test]
    procedure EveryStagedLineBecomesSalesLine()
    var
        OrderStaging: Record "CMC Order Staging";
        SalesLine: Record "Sales Line";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        TestLibrary.AddStagedLine(OrderStaging, 1, TestLibrary.CreateItemNo(10), 1, 10);
        TestLibrary.AddStagedLine(OrderStaging, 2, TestLibrary.CreateItemNo(20), 3, 20);

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderStaging."Created Document No.");
        Assert.AreEqual(2, SalesLine.Count(), 'Sales line count');
        SalesLine.Get(SalesLine."Document Type"::Order, OrderStaging."Created Document No.", 20000);
        Assert.AreEqual(3, SalesLine.Quantity, 'Quantity on the second line');
    end;

    /// <summary>
    /// Given two due staged orders, when the queue is processed, then both produce a sales document. Guards the
    /// loop against losing its place when a processed row leaves the filtered key.
    /// </summary>
    [Test]
    procedure ProcessPendingProcessesEveryDueOrder()
    var
        FirstOrderStaging: Record "CMC Order Staging";
        SecondOrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrderWithLine(FirstOrderStaging, 10);
        TestLibrary.CreateStagedOrderWithLine(SecondOrderStaging, 20);
        TestLibrary.MakeDue(FirstOrderStaging);
        TestLibrary.MakeDue(SecondOrderStaging);

        Assert.AreEqual(2, OrderIntake.ProcessPending(0), 'Documents created');

        FirstOrderStaging.Get(FirstOrderStaging."Entry No.");
        SecondOrderStaging.Get(SecondOrderStaging."Entry No.");
        Assert.AreEqual(FirstOrderStaging.Status::Completed, FirstOrderStaging.Status, 'First order status');
        Assert.AreEqual(SecondOrderStaging.Status::Completed, SecondOrderStaging.Status, 'Second order status');
    end;

    /// <summary>
    /// Given one due order, one order whose retry is not yet due and one completed order, when the queue is
    /// processed, then only the due order is attempted.
    /// </summary>
    [Test]
    procedure ProcessPendingSkipsRowsNotDue()
    var
        DueOrderStaging: Record "CMC Order Staging";
        LaterOrderStaging: Record "CMC Order Staging";
        DoneOrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        TestLibrary.CreateStagedOrderWithLine(DueOrderStaging, 10);
        TestLibrary.CreateStagedOrderWithLine(LaterOrderStaging, 10);
        TestLibrary.CreateStagedOrderWithLine(DoneOrderStaging, 10);
        TestLibrary.MakeDue(DueOrderStaging);
        LaterOrderStaging."Next Retry At" := CurrentDateTime() + 3600000;
        LaterOrderStaging.Modify();
        TestLibrary.MakeDue(DoneOrderStaging);
        DoneOrderStaging.Get(DoneOrderStaging."Entry No.");
        DoneOrderStaging.Status := DoneOrderStaging.Status::Completed;
        DoneOrderStaging.Modify();

        Assert.AreEqual(1, OrderIntake.ProcessPending(0), 'Documents created');

        LaterOrderStaging.Get(LaterOrderStaging."Entry No.");
        DoneOrderStaging.Get(DoneOrderStaging."Entry No.");
        Assert.AreEqual(0, LaterOrderStaging.Attempts, 'An order not yet due must not be attempted');
        Assert.AreEqual(0, DoneOrderStaging.Attempts, 'A completed order must not be attempted again');
    end;

    /// <summary>
    /// Given three due orders, when the queue is processed with a batch size of two, then exactly two are
    /// attempted and the third stays pending for the next run.
    /// </summary>
    [Test]
    procedure ProcessPendingHonoursBatchSize()
    var
        OrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
        Index: Integer;
    begin
        Initialize();
        for Index := 1 to 3 do begin
            TestLibrary.CreateStagedOrderWithLine(OrderStaging, 10);
            TestLibrary.MakeDue(OrderStaging);
        end;

        Assert.AreEqual(2, OrderIntake.ProcessPending(2), 'Documents created');

        OrderStaging.Reset();
        OrderStaging.SetRange(Status, OrderStaging.Status::Pending);
        OrderStaging.SetRange(Attempts, 0);
        Assert.AreEqual(1, OrderStaging.Count(), 'Orders left for the next run');
    end;

    /// <summary>
    /// Given a staged order with a default unit of measure and a line without one, when it is processed, then the
    /// sales line is in the header's default unit.
    /// </summary>
    [Test]
    procedure LineWithoutUnitTakesHeaderDefault()
    var
        OrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
        ItemNo: Code[20];
        BoxCode: Code[10];
    begin
        Initialize();
        ItemNo := TestLibrary.CreateItemNo(10);
        BoxCode := TestLibrary.AddItemUnitOfMeasure(ItemNo, 6);
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        OrderStaging."Default Unit of Measure" := BoxCode;
        OrderStaging.Modify();
        TestLibrary.AddStagedLine(OrderStaging, 1, ItemNo, 1, 0);

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        Assert.AreEqual(BoxCode, CreatedLineUnitOfMeasure(OrderStaging), 'Unit of Measure Code');
    end;

    /// <summary>
    /// Given a staged order with a default unit of measure and a line carrying its own unit, when it is
    /// processed, then the line's unit wins.
    /// </summary>
    [Test]
    procedure LineUnitWinsOverHeaderDefault()
    var
        Item: Record Item;
        OrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        Item.Get(TestLibrary.CreateItemNo(10));
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        OrderStaging."Default Unit of Measure" := TestLibrary.AddItemUnitOfMeasure(Item."No.", 6);
        OrderStaging.Modify();
        TestLibrary.AddStagedLine(OrderStaging, 1, Item."No.", 1, 0);
        TestLibrary.SetStagedLineUnitOfMeasure(OrderStaging, 1, Item."Base Unit of Measure");

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        Assert.AreEqual(Item."Base Unit of Measure", CreatedLineUnitOfMeasure(OrderStaging), 'Unit of Measure Code');
    end;

    /// <summary>
    /// Given no unit of measure on the line or the header and an item with a sales unit, when the order is
    /// processed, then the sales line is in the item's sales unit.
    /// </summary>
    [Test]
    procedure NoUnitAnywhereUsesItemSalesUnit()
    var
        OrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
        ItemNo: Code[20];
        BoxCode: Code[10];
    begin
        Initialize();
        ItemNo := TestLibrary.CreateItemNo(10);
        BoxCode := TestLibrary.AddItemUnitOfMeasure(ItemNo, 6);
        TestLibrary.SetItemSalesUnitOfMeasure(ItemNo, BoxCode);
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        TestLibrary.AddStagedLine(OrderStaging, 1, ItemNo, 1, 0);

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        Assert.AreEqual(BoxCode, CreatedLineUnitOfMeasure(OrderStaging), 'Unit of Measure Code');
    end;

    /// <summary>
    /// Given no unit of measure on the line, the header or the item's sales unit, when the order is processed,
    /// then the sales line is in the item's base unit.
    /// </summary>
    [Test]
    procedure NoUnitAnywhereUsesItemBaseUnit()
    var
        Item: Record Item;
        OrderStaging: Record "CMC Order Staging";
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize();
        Item.Get(TestLibrary.CreateItemNo(10));
        TestLibrary.SetItemSalesUnitOfMeasure(Item."No.", '');
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        TestLibrary.AddStagedLine(OrderStaging, 1, Item."No.", 1, 0);

        Assert.IsTrue(OrderIntake.ProcessOne(OrderStaging), 'ProcessOne must report success');

        Assert.AreEqual(Item."Base Unit of Measure", CreatedLineUnitOfMeasure(OrderStaging), 'Unit of Measure Code');
    end;

    local procedure CreatedLineUnitOfMeasure(var OrderStaging: Record "CMC Order Staging"): Code[10]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(SalesLine."Document Type"::Order, OrderStaging."Created Document No.", 10000);
        exit(SalesLine."Unit of Measure Code");
    end;

    local procedure Initialize()
    begin
        TestLibrary.RestoreDefaultImplementations();
        TestLibrary.ResetSetup();
        TestLibrary.SetRetryPolicy(5, 60);
        TestLibrary.DisableSalesWarnings();
        TestLibrary.DeleteAllStaging();
    end;

    local procedure FindFirstLine(var OrderStaging: Record "CMC Order Staging"; var OrderStagingLine: Record "CMC Order Staging Line")
    begin
        OrderStagingLine.SetRange("Entry No.", OrderStaging."Entry No.");
        OrderStagingLine.FindFirst();
    end;
}
