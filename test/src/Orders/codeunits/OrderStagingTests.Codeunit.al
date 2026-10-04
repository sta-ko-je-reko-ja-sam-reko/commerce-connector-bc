namespace CommerceConnector.Test;

using CommerceConnector.Orders;
using System.TestLibraries.Utilities;

codeunit 74003 "CMC Order Staging Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "CMC Test Library";
        MissingKeyTok: Label 'must carry an idempotency key', Locked = true;

    /// <summary>
    /// Given a staged order without an idempotency key, when the insert logic runs, then it is rejected.
    /// </summary>
    [Test]
    procedure InsertWithoutIdempotencyKeyIsRejected()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
        OrderStagingLogic: Codeunit "CMC Order Staging Logic";
    begin
        TempOrderStaging.Init();

        asserterror OrderStagingLogic.Trigger_OnInsert(TempOrderStaging);

        Assert.ExpectedError(MissingKeyTok);
    end;

    /// <summary>
    /// Given a staged order that arrives claiming to be completed with a stale retry time, when the insert logic
    /// runs, then it is reset to pending and stamped as received and due now, so a caller cannot skip intake.
    /// </summary>
    [Test]
    procedure InsertStampsReceivedAndQueuesAsPending()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
        OrderStagingLogic: Codeunit "CMC Order Staging Logic";
        Before: DateTime;
    begin
        TempOrderStaging.Init();
        TempOrderStaging."Idempotency Key" := TestLibrary.NewIdempotencyKey();
        TempOrderStaging.Status := TempOrderStaging.Status::Completed;
        TempOrderStaging."Next Retry At" := CreateDateTime(DMY2Date(1, 1, 2000), 0T);
        Before := CurrentDateTime();

        OrderStagingLogic.Trigger_OnInsert(TempOrderStaging);

        Assert.AreEqual(TempOrderStaging.Status::Pending, TempOrderStaging.Status, 'Status');
        Assert.IsTrue(TempOrderStaging."Received At" >= Before, 'Received At must be stamped with the current time');
        Assert.IsTrue(TempOrderStaging."Next Retry At" >= Before, 'A new staged order must be due immediately');
    end;

    /// <summary>
    /// Given the default logic, when a staged order without a key is inserted with triggers, then the table
    /// delegates to the logic and the insert is rejected.
    /// </summary>
    [Test]
    procedure TableInsertRunsDefaultLogic()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
    begin
        TempOrderStaging.Init();
        TempOrderStaging."Entry No." := 1;

        asserterror TempOrderStaging.Insert(true);

        Assert.ExpectedError(MissingKeyTok);
    end;

    /// <summary>
    /// Given an injected fake, when a staged order the default logic would reject is inserted, then the insert
    /// reaches the fake and the default logic does not run.
    /// </summary>
    [Test]
    procedure TableInsertDelegatesToInjectedLogic()
    var
        TempOrderStaging: Record "CMC Order Staging" temporary;
        FakeOrderStaging: Codeunit "CMC Fake Order Staging";
    begin
        TempOrderStaging.Define(FakeOrderStaging);
        TempOrderStaging.Init();
        TempOrderStaging."Entry No." := 1;

        TempOrderStaging.Insert(true);

        Assert.AreEqual(1, FakeOrderStaging.InsertCallCount(), 'Insert delegated to the fake');
        Assert.AreEqual(0DT, TempOrderStaging."Received At", 'The default logic must not have run');
    end;
}
