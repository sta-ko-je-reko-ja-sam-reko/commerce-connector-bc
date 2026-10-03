namespace CommerceConnector.General;

enum 70061 "CMC Commerce Document Type"
{
    Extensible = true;
    Caption = 'Commerce Document Type';

    value(0; Order) { Caption = 'Order'; }
    value(1; Quote) { Caption = 'Quote'; }
}
