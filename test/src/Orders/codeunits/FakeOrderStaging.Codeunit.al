namespace CommerceConnector.Test;

using CommerceConnector.Orders;

codeunit 74051 "CMC Fake Order Staging" implements "CMC IOrderStaging"
{
    Access = Public;

    var
        OnInsertCalls: Integer;

    procedure Trigger_OnInsert(var OrderStaging: Record "CMC Order Staging")
    begin
        OnInsertCalls += 1;
    end;

    /// <summary>
    /// Returns how many times the insert trigger delegated to this fake.
    /// </summary>
    procedure InsertCallCount(): Integer
    begin
        exit(OnInsertCalls);
    end;
}
