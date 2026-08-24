namespace CommerceConnector.General;

using CommerceConnector.Catalogue;
using CommerceConnector.Events;
using CommerceConnector.Orders;
using CommerceConnector.Pricing;
using CommerceConnector.Setup;

permissionset 57191 "CMC Commerce - Read"
{
    Assignable = true;
    Caption = 'Commerce Connector - Read', Locked = true;

    Permissions =
        tabledata "CMC Commerce Setup" = R,
        tabledata "CMC Order Staging" = R,
        tabledata "CMC Order Staging Line" = R,
        tabledata "CMC Change Outbox" = R,
        table "CMC Commerce Setup" = X,
        table "CMC Order Staging" = X,
        table "CMC Order Staging Line" = X,
        table "CMC Change Outbox" = X,
        table "CMC Price Request Line" = X,
        page "CMC Commerce Setup" = X,
        page "CMC Order Staging List" = X,
        page "CMC Change Outbox List" = X,
        page "CMC API Category" = X,
        page "CMC API Order" = X,
        page "CMC API Order Line" = X,
        page "CMC API Change Outbox" = X,
        query "CMC API Item Delta" = X;
}
