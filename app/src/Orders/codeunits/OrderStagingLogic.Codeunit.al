namespace CommerceConnector.Orders;

codeunit 70012 "CMC Order Staging Logic" implements "CMC IOrderStaging"
{
    Access = Public;

    var
        MissingIdempotencyKeyErr: Label 'A staged order must carry an idempotency key. Without one a retried submission cannot be recognised and would create a second document.';

    procedure Trigger_OnInsert(var OrderStaging: Record "CMC Order Staging")
    begin
        if OrderStaging."Idempotency Key" = '' then
            Error(MissingIdempotencyKeyErr);

        OrderStaging."Received At" := CurrentDateTime();
        OrderStaging.Status := OrderStaging.Status::Pending;
        OrderStaging."Next Retry At" := CurrentDateTime();
    end;
}
