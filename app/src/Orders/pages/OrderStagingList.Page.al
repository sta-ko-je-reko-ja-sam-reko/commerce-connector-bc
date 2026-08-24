namespace CommerceConnector.Orders;

using CommerceConnector.General;
using System.Utilities;

page 57113 "CMC Order Staging List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "CMC Order Staging";
    Caption = 'Commerce Order Staging';
    InsertAllowed = false;
    ModifyAllowed = false;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Platform Order Id"; Rec."Platform Order Id") { }
                field("Customer No."; Rec."Customer No.") { }
                field("Document Type"; Rec."Document Type") { }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field(Attempts; Rec.Attempts) { }
                field("Created Document No."; Rec."Created Document No.") { }
                field("Received At"; Rec."Received At") { }
                field("Next Retry At"; Rec."Next Retry At") { }
                field("Last Error"; Rec."Last Error") { }
                field("Correlation Id"; Rec."Correlation Id") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetryNow)
            {
                ApplicationArea = All;
                Caption = 'Retry Now';
                ToolTip = 'Schedules the selected staged orders for an immediate retry.';
                Image = Restore;

                trigger OnAction()
                begin
                    RetrySelected();
                end;
            }
            action(ProcessQueue)
            {
                ApplicationArea = All;
                Caption = 'Process Queue';
                ToolTip = 'Processes every staged order that is currently due.';
                Image = Post;

                trigger OnAction()
                var
                    OrderIntake: Codeunit "CMC Order Intake";
                begin
                    Message(ProcessedMsg, OrderIntake.ProcessPending(0));
                end;
            }
        }
    }

    var
        StatusStyle: Text;
        ProcessedMsg: Label '%1 staged order(s) produced a sales document.', Comment = '%1 = number of documents created';
        RetryQst: Label 'Schedule the selected staged order(s) for an immediate retry?';

    trigger OnAfterGetRecord()
    begin
        StatusStyle := StyleFor(Rec.Status);
    end;

    local procedure StyleFor(StagingStatus: Enum "CMC Staging Status"): Text
    begin
        case StagingStatus of
            StagingStatus::Completed:
                exit('Favorable');
            StagingStatus::Failed,
            StagingStatus::Abandoned:
                exit('Unfavorable');
            StagingStatus::Processing:
                exit('Ambiguous');
            else
                exit('Standard');
        end;
    end;

    local procedure RetrySelected()
    var
        SelectedStaging: Record "CMC Order Staging";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(RetryQst, false) then
            exit;

        CurrPage.SetSelectionFilter(SelectedStaging);
        if SelectedStaging.FindSet() then
            repeat
                if SelectedStaging.Status in [SelectedStaging.Status::Failed, SelectedStaging.Status::Abandoned] then begin
                    SelectedStaging.Status := SelectedStaging.Status::Pending;
                    SelectedStaging."Next Retry At" := CurrentDateTime();
                    SelectedStaging.Modify(true);
                end;
            until SelectedStaging.Next() = 0;

        CurrPage.Update(false);
    end;
}
