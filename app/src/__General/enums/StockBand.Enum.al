namespace CommerceConnector.General;

enum 70063 "CMC Stock Band"
{
    Extensible = true;
    Caption = 'Stock Band';

    value(0; Unknown) { Caption = 'Unknown'; }
    value(1; OutOfStock) { Caption = 'Out of Stock'; }
    value(2; Low) { Caption = 'Low'; }
    value(3; InStock) { Caption = 'In Stock'; }
}
