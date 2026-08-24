namespace CommerceConnector.Orders;

using CommerceConnector.General;
using CommerceConnector.Setup;
using Microsoft.Sales.Document;

codeunit 57113 "CMC Order Intake" implements "CMC IOrderIntake"
{
    Access = Public;
    Permissions = tabledata "CMC Order Staging" = rimd,
                  tabledata "CMC Order Staging Line" = r;

    var
        PriceMismatchErr: Label 'Line %1 was submitted at %2 but Business Central resolved %3. The submission is rejected rather than repriced.', Comment = '%1 = line reference, %2 = submitted price, %3 = resolved price';
        NoLinesErr: Label 'Staged order %1 carries no lines.', Comment = '%1 = platform order id';
        AbandonedTxt: Label 'Abandoned after %1 attempts. Last error: %2', Comment = '%1 = attempt count, %2 = last error text';

    /// <summary>
    /// Processes staged orders that are due, up to the supplied batch size.
    /// </summary>
    /// <param name="BatchSize">Maximum number of staged orders to attempt. Zero means no limit.</param>
    /// <returns>The number of staged orders that produced a sales document.</returns>
    procedure ProcessPending(BatchSize: Integer): Integer
    var
        OrderStaging: Record "CMC Order Staging";
        Succeeded: Integer;
        Attempted: Integer;
    begin
        OrderStaging.SetCurrentKey(Status, "Next Retry At");
        OrderStaging.SetRange(Status, OrderStaging.Status::Pending);
        OrderStaging.SetFilter("Next Retry At", '<=%1', CurrentDateTime());

        if OrderStaging.FindSet() then
            repeat
                Attempted += 1;
                if ProcessOne(OrderStaging) then
                    Succeeded += 1;
            until (OrderStaging.Next() = 0) or ((BatchSize > 0) and (Attempted >= BatchSize));

        exit(Succeeded);
    end;

    /// <summary>
    /// Attempts one staged order and records the outcome on the staging row.
    /// </summary>
    /// <param name="OrderStaging">The staged order to process. Updated in place with the result.</param>
    /// <returns>True when a sales document was created.</returns>
    procedure ProcessOne(var OrderStaging: Record "CMC Order Staging"): Boolean
    var
        CreatedDocumentNo: Code[20];
    begin
        OrderStaging.Status := OrderStaging.Status::Processing;
        OrderStaging.Attempts += 1;
        OrderStaging.Modify(true);
        Commit();

        ClearLastError();
        if not TryCreateDocument(OrderStaging, CreatedDocumentNo) then begin
            MarkFailed(OrderStaging, GetLastErrorText());
            exit(false);
        end;

        OrderStaging."Created Document No." := CreatedDocumentNo;
        OrderStaging.Status := OrderStaging.Status::Completed;
        OrderStaging."Completed At" := CurrentDateTime();
        OrderStaging."Last Error" := '';
        OrderStaging.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Records a failed attempt, scheduling a retry or abandoning the row once attempts are exhausted.
    /// </summary>
    /// <param name="OrderStaging">The staged order that failed.</param>
    /// <param name="FailureReason">The error text to retain for the operator.</param>
    procedure MarkFailed(var OrderStaging: Record "CMC Order Staging"; FailureReason: Text)
    var
        CommerceSetup: Record "CMC Commerce Setup";
    begin
        CommerceSetup.GetSetup();
        OrderStaging."Last Error" := CopyStr(FailureReason, 1, MaxStrLen(OrderStaging."Last Error"));

        if OrderStaging.Attempts >= CommerceSetup."Order Intake Max Attempts" then begin
            OrderStaging.Status := OrderStaging.Status::Abandoned;
            OrderStaging."Last Error" := CopyStr(
                StrSubstNo(AbandonedTxt, OrderStaging.Attempts, OrderStaging."Last Error"),
                1, MaxStrLen(OrderStaging."Last Error"));
        end else begin
            OrderStaging.Status := OrderStaging.Status::Pending;
            OrderStaging."Next Retry At" := NextRetryAt(CommerceSetup."Retry Backoff Seconds", OrderStaging.Attempts);
        end;

        OrderStaging.Modify(true);
        Commit();
    end;

    [TryFunction]
    local procedure TryCreateDocument(var OrderStaging: Record "CMC Order Staging"; var CreatedDocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateHeader(OrderStaging, SalesHeader);
        CreateLines(OrderStaging, SalesHeader);
        CreatedDocumentNo := SalesHeader."No.";
    end;

    local procedure CreateHeader(var OrderStaging: Record "CMC Order Staging"; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentTypeFor(OrderStaging."Document Type"));
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", OrderStaging."Customer No.");

        if OrderStaging."Ship-to Code" <> '' then
            SalesHeader.Validate("Ship-to Code", OrderStaging."Ship-to Code");
        if OrderStaging."Currency Code" <> '' then
            SalesHeader.Validate("Currency Code", OrderStaging."Currency Code");
        if OrderStaging."Location Code" <> '' then
            SalesHeader.Validate("Location Code", OrderStaging."Location Code");
        if OrderStaging."Requested Delivery Date" <> 0D then
            SalesHeader.Validate("Requested Delivery Date", OrderStaging."Requested Delivery Date");

        SalesHeader."External Document No." := CopyStr(OrderStaging."External Reference", 1, MaxStrLen(SalesHeader."External Document No."));
        SalesHeader.Modify(true);
    end;

    local procedure CreateLines(var OrderStaging: Record "CMC Order Staging"; var SalesHeader: Record "Sales Header")
    var
        StagingLine: Record "CMC Order Staging Line";
    begin
        StagingLine.SetRange("Entry No.", OrderStaging."Entry No.");
        if not StagingLine.FindSet() then
            Error(NoLinesErr, OrderStaging."Platform Order Id");

        repeat
            CreateLine(StagingLine, SalesHeader);
        until StagingLine.Next() = 0;
    end;

    local procedure CreateLine(var StagingLine: Record "CMC Order Staging Line"; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := StagingLine."Line No." * 10000;
        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", StagingLine."Item No.");

        if StagingLine."Variant Code" <> '' then
            SalesLine.Validate("Variant Code", StagingLine."Variant Code");
        if StagingLine."Location Code" <> '' then
            SalesLine.Validate("Location Code", StagingLine."Location Code");
        if StagingLine."Unit of Measure Code" <> '' then
            SalesLine.Validate("Unit of Measure Code", StagingLine."Unit of Measure Code");

        SalesLine.Validate(Quantity, StagingLine.Quantity);

        if StagingLine."Requested Delivery Date" <> 0D then
            SalesLine.Validate("Requested Delivery Date", StagingLine."Requested Delivery Date");

        AssertAgreedPrice(StagingLine, SalesLine);
        SalesLine.Modify(true);
    end;

    local procedure AssertAgreedPrice(var StagingLine: Record "CMC Order Staging Line"; var SalesLine: Record "Sales Line")
    begin
        if StagingLine."Agreed Unit Price" = 0 then
            exit;

        if Round(SalesLine."Unit Price") <> Round(StagingLine."Agreed Unit Price") then
            Error(PriceMismatchErr, StagingLine."Line Ref", StagingLine."Agreed Unit Price", SalesLine."Unit Price");
    end;

    local procedure DocumentTypeFor(CommerceDocumentType: Enum "CMC Commerce Document Type"): Enum "Sales Document Type"
    begin
        case CommerceDocumentType of
            CommerceDocumentType::Quote:
                exit(Enum::"Sales Document Type"::Quote);
            else
                exit(Enum::"Sales Document Type"::Order);
        end;
    end;

    local procedure NextRetryAt(BackoffSeconds: Integer; Attempts: Integer): DateTime
    var
        DelaySeconds: Integer;
        BoundedAttempts: Integer;
    begin
        BoundedAttempts := Attempts;
        if BoundedAttempts > MaxBackoffDoublings() then
            BoundedAttempts := MaxBackoffDoublings();

        DelaySeconds := Round(BackoffSeconds * Power(2, BoundedAttempts - 1), 1);
        exit(CurrentDateTime() + (DelaySeconds * 1000));
    end;

    local procedure MaxBackoffDoublings(): Integer
    begin
        exit(10);
    end;
}
