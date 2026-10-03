namespace CommerceConnector.Orders;

using CommerceConnector.General;

codeunit 70014 "CMC Order Intake Job"
{
    Access = Public;

    trigger OnRun()
    var
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        ServiceLocator.OrderIntake().ProcessPending(BatchSize());
    end;

    local procedure BatchSize(): Integer
    begin
        exit(100);
    end;
}
