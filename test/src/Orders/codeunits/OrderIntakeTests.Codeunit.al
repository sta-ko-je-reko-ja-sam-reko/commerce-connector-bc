namespace CommerceConnector.Test;

using CommerceConnector.General;
using CommerceConnector.Orders;
using System.TestLibraries.Utilities;

codeunit 74004 "CMC Order Intake Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "CMC Test Library";
        FailureReasonTok: Label 'Simulated failure', Locked = true;
        AbandonedTok: Label 'Abandoned after 3 attempts', Locked = true;

    /// <summary>
    /// Given a retry policy of five attempts and a 60 second backoff, when the first attempt fails, then the row
    /// returns to pending, keeps the error and becomes due again after one backoff interval.
    /// </summary>
    [Test]
    procedure FailureBelowAttemptLimitSchedulesRetry()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
    begin
        Initialize(5, 60);
        StageInMemory(TempOrderStaging, 1);

        MarkFailedAndAssertDelay(TempOrderStaging, 60);

        Assert.AreEqual(TempOrderStaging.Status::Pending, TempOrderStaging.Status, 'Status');
        Assert.AreEqual(FailureReasonTok, TempOrderStaging."Last Error", 'Last Error');
    end;

    /// <summary>
    /// Given a 60 second backoff, when the third attempt fails, then the delay has doubled twice to 240 seconds.
    /// </summary>
    [Test]
    procedure BackoffDoublesWithEachAttempt()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
    begin
        Initialize(5, 60);
        StageInMemory(TempOrderStaging, 3);

        MarkFailedAndAssertDelay(TempOrderStaging, 240);
    end;

    /// <summary>
    /// Given a one second backoff and a generous attempt limit, when the thirtieth attempt fails, then the delay
    /// stops doubling after ten attempts, at 512 seconds, instead of growing without bound.
    /// </summary>
    [Test]
    procedure BackoffIsBoundedAfterTenDoublings()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
    begin
        Initialize(50, 1);
        StageInMemory(TempOrderStaging, 30);

        MarkFailedAndAssertDelay(TempOrderStaging, 512);
    end;

    /// <summary>
    /// Given a retry policy of three attempts, when the third attempt fails, then the row is abandoned for the
    /// operator with the attempt count and the original error in Last Error.
    /// </summary>
    [Test]
    procedure FailureAtAttemptLimitAbandonsRow()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
        OrderIntake: Codeunit "CMC Order Intake";
    begin
        Initialize(3, 60);
        StageInMemory(TempOrderStaging, 3);

        OrderIntake.MarkFailed(TempOrderStaging, FailureReasonTok);

        Assert.AreEqual(TempOrderStaging.Status::Abandoned, TempOrderStaging.Status, 'Status');
        Assert.IsTrue(StrPos(TempOrderStaging."Last Error", AbandonedTok) > 0, 'Last Error must state the attempt count');
        Assert.IsTrue(StrPos(TempOrderStaging."Last Error", FailureReasonTok) > 0, 'Last Error must keep the original error');
    end;

    /// <summary>
    /// Given an error text longer than the field, when the attempt fails, then the text is truncated to fit
    /// rather than failing the failure handling itself.
    /// </summary>
    [Test]
    procedure LongFailureReasonIsTruncated()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
        OrderIntake: Codeunit "CMC Order Intake";
        LongReason: Text;
    begin
        Initialize(5, 60);
        StageInMemory(TempOrderStaging, 1);
        LongReason := PadStr('', 3000, 'x');

        OrderIntake.MarkFailed(TempOrderStaging, LongReason);

        Assert.AreEqual(MaxStrLen(TempOrderStaging."Last Error"), StrLen(TempOrderStaging."Last Error"), 'Last Error length');
    end;

    /// <summary>
    /// Given a fake order intake injected through the service locator, when the Job Queue entry point runs, then
    /// it delegates to the injected implementation with its batch size of 100.
    /// </summary>
    [Test]
    procedure JobQueueEntryDelegatesToLocatedIntake()
    var
        FakeOrderIntake: Codeunit "CMC Fake Order Intake";
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        TestLibrary.RestoreDefaultImplementations();
        ServiceLocator.ImplementOrderIntake(FakeOrderIntake);

        Codeunit.Run(Codeunit::"CMC Order Intake Job");
        TestLibrary.RestoreDefaultImplementations();

        Assert.AreEqual(1, FakeOrderIntake.ProcessPendingCallCount(), 'ProcessPending calls');
        Assert.AreEqual(100, FakeOrderIntake.LastRequestedBatchSize(), 'Batch size');
    end;

    local procedure Initialize(MaxAttempts: Integer; BackoffSeconds: Integer)
    begin
        TestLibrary.RestoreDefaultImplementations();
        TestLibrary.ResetSetup();
        TestLibrary.SetRetryPolicy(MaxAttempts, BackoffSeconds);
    end;

    local procedure StageInMemory(var TempOrderStaging: Record "CMC Order Staging" temporary; Attempts: Integer)
    begin
        TempOrderStaging.Init();
        TempOrderStaging."Entry No." := 1;
        TempOrderStaging."Idempotency Key" := TestLibrary.NewIdempotencyKey();
        TempOrderStaging.Status := TempOrderStaging.Status::Processing;
        TempOrderStaging.Attempts := Attempts;
        TempOrderStaging.Insert();
    end;

    local procedure MarkFailedAndAssertDelay(var TempOrderStaging: Record "CMC Order Staging" temporary; ExpectedDelaySeconds: Integer)
    var
        OrderIntake: Codeunit "CMC Order Intake";
        Before: DateTime;
        After: DateTime;
    begin
        Before := CurrentDateTime();
        OrderIntake.MarkFailed(TempOrderStaging, FailureReasonTok);
        After := CurrentDateTime();

        Assert.IsTrue(TempOrderStaging."Next Retry At" - Before >= ExpectedDelaySeconds * 1000, 'Retry scheduled too early');
        Assert.IsTrue(TempOrderStaging."Next Retry At" - After <= ExpectedDelaySeconds * 1000, 'Retry scheduled too late');
    end;
}
