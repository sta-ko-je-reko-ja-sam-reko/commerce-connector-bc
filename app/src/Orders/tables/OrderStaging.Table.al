namespace CommerceConnector.Orders;

using CommerceConnector.General;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;

table 70010 "CMC Order Staging"
{
    DataClassification = CustomerContent;
    Caption = 'Commerce Order Staging';
    LookupPageId = "CMC Order Staging List";
    DrillDownPageId = "CMC Order Staging List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the sequence number of the staged order.';
            AutoIncrement = true;
        }
        field(5; "Idempotency Key"; Code[64])
        {
            Caption = 'Idempotency Key';
            ToolTip = 'Specifies the key the caller generated for this submission. A repeated submission carries the same key and must not create a second document.';
            NotBlank = true;
        }
        field(6; "Platform Order Id"; Code[50])
        {
            Caption = 'Platform Order Id';
            ToolTip = 'Specifies the identifier the commerce platform assigned to this order before it reached Business Central.';
        }
        field(10; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the customer the order is created for.';
            TableRelation = Customer;
        }
        field(11; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies the alternate delivery address for the order.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(12; "Document Type"; Enum "CMC Commerce Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies whether the submission becomes a sales order or a sales quote.';
        }
        field(13; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency the order was priced in.';
        }
        field(14; "External Reference"; Text[100])
        {
            Caption = 'External Reference';
            ToolTip = 'Specifies the customer purchase-order reference supplied with the submission.';
        }
        field(15; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            ToolTip = 'Specifies the delivery date the customer asked for.';
        }
        field(16; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the default location the order is served from.';
            TableRelation = Location;
        }
        field(17; "Default Unit of Measure"; Code[10])
        {
            Caption = 'Default Unit of Measure';
            ToolTip = 'Specifies the unit of measure applied to lines that do not carry one.';
            TableRelation = "Unit of Measure";
        }
        field(30; Status; Enum "CMC Staging Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies where the staged order is in its processing cycle.';
        }
        field(31; Attempts; Integer)
        {
            Caption = 'Attempts';
            ToolTip = 'Specifies how many times processing has been attempted.';
        }
        field(32; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            ToolTip = 'Specifies the error returned by the most recent attempt.';
        }
        field(33; "Next Retry At"; DateTime)
        {
            Caption = 'Next Retry At';
            ToolTip = 'Specifies the earliest time the next attempt may run.';
        }
        field(34; "Created Document No."; Code[20])
        {
            Caption = 'Created Document No.';
            ToolTip = 'Specifies the sales document created from this submission.';
        }
        field(40; "Received At"; DateTime)
        {
            Caption = 'Received At';
            ToolTip = 'Specifies when the submission was accepted into staging.';
        }
        field(41; "Completed At"; DateTime)
        {
            Caption = 'Completed At';
            ToolTip = 'Specifies when the submission finished processing.';
        }
        field(42; "Correlation Id"; Text[50])
        {
            Caption = 'Correlation Id';
            ToolTip = 'Specifies the identifier that ties this submission to the originating request in the platform and in telemetry.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Idempotency; "Idempotency Key") { Unique = true; }
        key(Processing; Status, "Next Retry At") { }
        key(PlatformOrder; "Platform Order Id") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Platform Order Id", "Customer No.", Status) { }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    var
        ILogic: Interface "CMC IOrderStaging";
        ILogicDefined: Boolean;

    local procedure Logic(): Interface "CMC IOrderStaging"
    var
        DefaultImplementation: Codeunit "CMC Order Staging Logic";
    begin
        if not ILogicDefined then
            Define(DefaultImplementation);
        exit(ILogic);
    end;

    /// <summary>
    /// Injects an alternative staging implementation, for tests and dependent extensions.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "CMC IOrderStaging")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;
}
