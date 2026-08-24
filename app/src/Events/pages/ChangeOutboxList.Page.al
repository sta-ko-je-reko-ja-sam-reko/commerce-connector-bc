namespace CommerceConnector.Events;

page 57121 "CMC Change Outbox List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "CMC Change Outbox";
    Caption = 'Commerce Change Outbox';
    InsertAllowed = false;
    ModifyAllowed = false;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { }
                field(Topic; Rec.Topic) { }
                field("Entity Key"; Rec."Entity Key") { }
                field("Change Type"; Rec."Change Type") { }
                field("Changed At"; Rec."Changed At") { }
                field(Status; Rec.Status) { }
                field(Attempts; Rec.Attempts) { }
                field("Last Error"; Rec."Last Error") { }
            }
        }
    }
}
