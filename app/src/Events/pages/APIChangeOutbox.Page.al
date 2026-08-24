namespace CommerceConnector.Events;

page 57120 "CMC API Change Outbox"
{
    PageType = API;
    APIPublisher = 'stakojerekojasamreko';
    APIGroup = 'commerce';
    APIVersion = 'v1.0';
    EntityName = 'changeOutboxEntry';
    EntitySetName = 'changeOutbox';
    EntityCaption = 'Change Outbox Entry';
    EntitySetCaption = 'Change Outbox';
    SourceTable = "CMC Change Outbox";
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId) { Caption = 'System Id'; Editable = false; }
                field(entryNumber; Rec."Entry No.") { Caption = 'Entry Number'; Editable = false; }
                field(topic; Rec.Topic) { Caption = 'Topic'; Editable = false; }
                field(entityId; Rec."Entity Id") { Caption = 'Entity Id'; Editable = false; }
                field(entityKey; Rec."Entity Key") { Caption = 'Entity Key'; Editable = false; }
                field(changeType; Rec."Change Type") { Caption = 'Change Type'; Editable = false; }
                field(changedAt; Rec."Changed At") { Caption = 'Changed At'; Editable = false; }
                field(correlationId; Rec."Correlation Id") { Caption = 'Correlation Id'; Editable = false; }
                field(status; Rec.Status) { Caption = 'Status'; }
                field(attempts; Rec.Attempts) { Caption = 'Attempts'; }
                field(lastError; Rec."Last Error") { Caption = 'Last Error'; }
            }
        }
    }
}
