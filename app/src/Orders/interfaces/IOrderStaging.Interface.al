namespace CommerceConnector.Orders;

interface "CMC IOrderStaging"
{
    Access = Public;

    procedure Trigger_OnInsert(var OrderStaging: Record "CMC Order Staging")
}
