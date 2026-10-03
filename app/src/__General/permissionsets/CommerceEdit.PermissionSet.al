namespace CommerceConnector.General;

using CommerceConnector.Availability;
using CommerceConnector.Catalogue;
using CommerceConnector.Events;
using CommerceConnector.Orders;
using CommerceConnector.Pricing;
using CommerceConnector.Setup;

permissionset 70090 "CMC Commerce - Edit"
{
    Assignable = true;
    Caption = 'Commerce Connector - Edit', Locked = true;

    Permissions =
        tabledata "CMC Commerce Setup" = RIMD,
        tabledata "CMC Order Staging" = RIMD,
        tabledata "CMC Order Staging Line" = RIMD,
        tabledata "CMC Change Outbox" = RIMD,
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
        query "CMC API Item Delta" = X,
        codeunit "CMC Commerce Setup Logic" = X,
        codeunit "CMC Order Staging Logic" = X,
        codeunit "CMC Order Intake" = X,
        codeunit "CMC Order Intake Job" = X,
        codeunit "CMC Commerce Reactions" = X,
        codeunit "CMC Item Events" = X,
        codeunit "CMC Service Locator" = X,
        codeunit "CMC Install" = X;
}
