namespace CommerceConnector.Test;

using CommerceConnector.Orders;

codeunit 74053 "CMC Fake Order Intake" implements "CMC IOrderIntake"
{
    Access = Public;

    var
        ProcessPendingCalls: Integer;
        LastBatchSize: Integer;

    procedure ProcessPending(BatchSize: Integer): Integer
    begin
        ProcessPendingCalls += 1;
        LastBatchSize := BatchSize;
        exit(0);
    end;

    procedure ProcessOne(var OrderStaging: Record "CMC Order Staging"): Boolean
    begin
        exit(false);
    end;

    procedure MarkFailed(var OrderStaging: Record "CMC Order Staging"; FailureReason: Text)
    begin
    end;

    /// <summary>
    /// Returns how many times ProcessPending was called on this fake.
    /// </summary>
    procedure ProcessPendingCallCount(): Integer
    begin
        exit(ProcessPendingCalls);
    end;

    /// <summary>
    /// Returns the batch size passed to the most recent ProcessPending call.
    /// </summary>
    procedure LastRequestedBatchSize(): Integer
    begin
        exit(LastBatchSize);
    end;
}
