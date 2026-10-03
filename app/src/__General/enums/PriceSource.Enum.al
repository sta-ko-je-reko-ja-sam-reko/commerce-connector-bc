namespace CommerceConnector.General;

enum 70062 "CMC Price Source"
{
    Extensible = true;
    Caption = 'Price Source';

    value(0; List) { Caption = 'List'; }
    value(1; Contract) { Caption = 'Contract'; }
    value(2; CustomerGroup) { Caption = 'Customer Group'; }
    value(3; Campaign) { Caption = 'Campaign'; }
    value(4; VolumeBreak) { Caption = 'Volume Break'; }
}
