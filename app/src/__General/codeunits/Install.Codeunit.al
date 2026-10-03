namespace CommerceConnector.General;

using CommerceConnector.Orders;
using CommerceConnector.Setup;
using System.Threading;

codeunit 70031 "CMC Install"
{
    Subtype = Install;
    Access = Internal;
    Permissions = tabledata "CMC Commerce Setup" = rim,
                  tabledata "Job Queue Entry" = rim;

    var
        OrderIntakeJobDescriptionTxt: Label 'Commerce order intake';

    trigger OnInstallAppPerCompany()
    begin
        EnsureSetup();
        EnsureOrderIntakeJob();
    end;

    local procedure EnsureSetup()
    var
        CommerceSetup: Record "CMC Commerce Setup";
    begin
        CommerceSetup.GetSetup();
    end;

    local procedure EnsureOrderIntakeJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"CMC Order Intake Job");
        if not JobQueueEntry.IsEmpty() then
            exit;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"CMC Order Intake Job";
        JobQueueEntry.Description := CopyStr(OrderIntakeJobDescriptionTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."No. of Minutes between Runs" := 5;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Insert(true);
    end;
}
