namespace CommerceConnector.Setup;

table 70000 "CMC Commerce Setup"
{
    DataClassification = CustomerContent;
    Caption = 'Commerce Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            ToolTip = 'Specifies the key of the single commerce setup record.';
        }
        field(10; "Catalogue Page Size"; Integer)
        {
            Caption = 'Catalogue Page Size';
            ToolTip = 'Specifies how many rows a single catalogue delta page returns. The contract caps this at 1000.';
            InitValue = 500;
            MinValue = 1;

            trigger OnValidate()
            begin
                Logic().Validate_CataloguePageSize(Rec);
            end;
        }
        field(11; "Bulk Line Cap"; Integer)
        {
            Caption = 'Bulk Line Cap';
            ToolTip = 'Specifies how many lines a single price or availability request may contain. The contract caps this at 100.';
            InitValue = 100;
            MinValue = 1;

            trigger OnValidate()
            begin
                Logic().Validate_BulkLineCap(Rec);
            end;
        }
        field(20; "Low Stock Threshold"; Decimal)
        {
            Caption = 'Low Stock Threshold';
            ToolTip = 'Specifies the quantity at or below which an item is published as low rather than in stock.';
            InitValue = 5;
            MinValue = 0;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Logic().Validate_LowStockThreshold(Rec);
            end;
        }
        field(30; "Order Intake Max Attempts"; Integer)
        {
            Caption = 'Order Intake Max Attempts';
            ToolTip = 'Specifies how many times a staged order is retried before it is abandoned for manual handling.';
            InitValue = 5;
            MinValue = 1;
        }
        field(31; "Retry Backoff Seconds"; Integer)
        {
            Caption = 'Retry Backoff Seconds';
            ToolTip = 'Specifies the base delay before a failed order is retried. The delay doubles with each attempt.';
            InitValue = 60;
            MinValue = 1;
        }
        field(40; "Staging Retention Days"; Integer)
        {
            Caption = 'Staging Retention Days';
            ToolTip = 'Specifies how long completed staging rows are kept before they are removed.';
            InitValue = 90;
            MinValue = 1;
        }
        field(50; "Publish Business Events"; Boolean)
        {
            Caption = 'Publish Business Events';
            ToolTip = 'Specifies whether catalogue, price, stock and order events are published to external subscribers.';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    var
        ILogic: Interface "CMC ICommerceSetup";
        ILogicDefined: Boolean;

    local procedure Logic(): Interface "CMC ICommerceSetup"
    var
        DefaultImplementation: Codeunit "CMC Commerce Setup Logic";
    begin
        if not ILogicDefined then
            Define(DefaultImplementation);
        exit(ILogic);
    end;

    /// <summary>
    /// Injects an alternative setup implementation, for tests and dependent extensions.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "CMC ICommerceSetup")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    /// <summary>
    /// Reads the single setup record, creating it with defaults when it does not yet exist.
    /// </summary>
    procedure GetSetup()
    begin
        if Rec.Get() then
            exit;
        Rec.Init();
        Rec.Insert(true);
    end;
}
