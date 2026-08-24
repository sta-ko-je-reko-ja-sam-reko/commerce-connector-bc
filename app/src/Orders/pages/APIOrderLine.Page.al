namespace CommerceConnector.Orders;

page 57112 "CMC API Order Line"
{
    PageType = API;
    APIPublisher = 'stakojerekojasamreko';
    APIGroup = 'commerce';
    APIVersion = 'v1.0';
    EntityName = 'orderLine';
    EntitySetName = 'orderLines';
    EntityCaption = 'Commerce Order Line';
    EntitySetCaption = 'Commerce Order Lines';
    SourceTable = "CMC Order Staging Line";
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
                field(orderEntryNumber; Rec."Entry No.") { Caption = 'Order Entry Number'; }
                field(lineNumber; Rec."Line No.") { Caption = 'Line Number'; }
                field(lineRef; Rec."Line Ref") { Caption = 'Line Ref'; }
                field(itemNumber; Rec."Item No.") { Caption = 'Item Number'; }
                field(variantCode; Rec."Variant Code") { Caption = 'Variant Code'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                field(agreedUnitPrice; Rec."Agreed Unit Price") { Caption = 'Agreed Unit Price'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
                field(requestedDeliveryDate; Rec."Requested Delivery Date") { Caption = 'Requested Delivery Date'; }
            }
        }
    }
}
