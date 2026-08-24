namespace CommerceConnector.Orders;

interface "CMC IOrderIntake"
{
    Access = Public;

    procedure ProcessPending(BatchSize: Integer): Integer
    procedure ProcessOne(var OrderStaging: Record "CMC Order Staging"): Boolean
    procedure MarkFailed(var OrderStaging: Record "CMC Order Staging"; FailureReason: Text)
}
