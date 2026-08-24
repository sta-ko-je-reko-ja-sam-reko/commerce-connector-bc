namespace CommerceConnector.Events;

using CommerceConnector.General;

table 57120 "CMC Change Outbox"
{
    DataClassification = CustomerContent;
    Caption = 'Commerce Change Outbox';
    LookupPageId = "CMC Change Outbox List";
    DrillDownPageId = "CMC Change Outbox List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the sequence number of the outbox entry.';
            AutoIncrement = true;
        }
        field(10; Topic; Text[100])
        {
            Caption = 'Topic';
            ToolTip = 'Specifies the channel the change is published on, for example catalogue.item.changed.';
        }
        field(11; "Entity Id"; Guid)
        {
            Caption = 'Entity Id';
            ToolTip = 'Specifies the system identifier of the record that changed.';
        }
        field(12; "Entity Key"; Text[100])
        {
            Caption = 'Entity Key';
            ToolTip = 'Specifies the business key of the record that changed, for readability in support.';
        }
        field(13; "Change Type"; Text[20])
        {
            Caption = 'Change Type';
            ToolTip = 'Specifies whether the record was created, updated, blocked or deleted.';
        }
        field(14; "Changed At"; DateTime)
        {
            Caption = 'Changed At';
            ToolTip = 'Specifies when the change was recorded.';
        }
        field(30; Status; Enum "CMC Staging Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the entry is still waiting to be collected.';
        }
        field(31; Attempts; Integer)
        {
            Caption = 'Attempts';
            ToolTip = 'Specifies how many times delivery has been attempted.';
        }
        field(32; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            ToolTip = 'Specifies the error returned by the most recent delivery attempt.';
        }
        field(33; "Next Retry At"; DateTime)
        {
            Caption = 'Next Retry At';
            ToolTip = 'Specifies the earliest time the next delivery attempt may run.';
        }
        field(40; "Correlation Id"; Text[50])
        {
            Caption = 'Correlation Id';
            ToolTip = 'Specifies the identifier that ties this entry to the originating request in telemetry.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Delivery; Status, "Next Retry At") { }
        key(Entity; Topic, "Entity Id") { }
    }
}
