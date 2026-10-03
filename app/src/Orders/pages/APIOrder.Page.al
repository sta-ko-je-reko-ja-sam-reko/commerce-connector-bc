namespace CommerceConnector.Orders;

page 70011 "CMC API Order"
{
    PageType = API;
    APIPublisher = 'stakojerekojasamreko';
    APIGroup = 'commerce';
    APIVersion = 'v1.0';
    EntityName = 'order';
    EntitySetName = 'orders';
    EntityCaption = 'Commerce Order';
    EntitySetCaption = 'Commerce Orders';
    SourceTable = "CMC Order Staging";
    DelayedInsert = true;
    Extensible = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId) { Caption = 'System Id'; Editable = false; }
                field(idempotencyKey; Rec."Idempotency Key") { Caption = 'Idempotency Key'; }
                field(platformOrderId; Rec."Platform Order Id") { Caption = 'Platform Order Id'; }
                field(customerNumber; Rec."Customer No.") { Caption = 'Customer Number'; }
                field(shipToCode; Rec."Ship-to Code") { Caption = 'Ship To Code'; }
                field(documentType; Rec."Document Type") { Caption = 'Document Type'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'Currency Code'; }
                field(externalReference; Rec."External Reference") { Caption = 'External Reference'; }
                field(requestedDeliveryDate; Rec."Requested Delivery Date") { Caption = 'Requested Delivery Date'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
                field(correlationId; Rec."Correlation Id") { Caption = 'Correlation Id'; }
                field(status; Rec.Status) { Caption = 'Status'; Editable = false; }
                field(attempts; Rec.Attempts) { Caption = 'Attempts'; Editable = false; }
                field(createdDocumentNumber; Rec."Created Document No.") { Caption = 'Created Document Number'; Editable = false; }
                field(lastError; Rec."Last Error") { Caption = 'Last Error'; Editable = false; }
                field(receivedAt; Rec."Received At") { Caption = 'Received At'; Editable = false; }
                field(completedAt; Rec."Completed At") { Caption = 'Completed At'; Editable = false; }
            }
        }
    }
}
