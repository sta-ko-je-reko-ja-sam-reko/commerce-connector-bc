namespace CommerceConnector.General;

enum 57160 "CMC Staging Status"
{
    Extensible = true;
    Caption = 'Staging Status';

    value(0; Pending) { Caption = 'Pending'; }
    value(1; Processing) { Caption = 'Processing'; }
    value(2; Completed) { Caption = 'Completed'; }
    value(3; Failed) { Caption = 'Failed'; }
    value(4; Abandoned) { Caption = 'Abandoned'; }
}
