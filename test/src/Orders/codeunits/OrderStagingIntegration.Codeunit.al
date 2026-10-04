namespace CommerceConnector.Test;

using CommerceConnector.General;
using CommerceConnector.Orders;
using System.TestLibraries.Utilities;

codeunit 74006 "CMC Order Staging Integration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TestLibrary: Codeunit "CMC Test Library";
        ProcessedTok: Label '1 staged order(s) produced a sales document', Locked = true;

    /// <summary>
    /// Given a staged order, when a second submission arrives with the same idempotency key, then the database
    /// rejects it, so a replayed message cannot create a second document.
    /// </summary>
    [Test]
    procedure DuplicateIdempotencyKeyIsRejected()
    var
        OrderStaging: Record "CMC Order Staging";
        DuplicateOrderStaging: Record "CMC Order Staging";
    begin
        Initialize();
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);

        DuplicateOrderStaging.Init();
        DuplicateOrderStaging."Idempotency Key" := OrderStaging."Idempotency Key";
        DuplicateOrderStaging."Customer No." := OrderStaging."Customer No.";
        asserterror DuplicateOrderStaging.Insert(true);

        Assert.AreNotEqual('', GetLastErrorText(), 'The duplicate insert must fail with an error');
    end;

    /// <summary>
    /// Given a new submission, when it is inserted through its triggers as the API page does, then it receives an
    /// entry number and is queued as pending and due.
    /// </summary>
    [Test]
    procedure InsertedSubmissionIsQueuedAsPending()
    var
        OrderStaging: Record "CMC Order Staging";
        StoredOrderStaging: Record "CMC Order Staging";
    begin
        Initialize();

        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);

        Assert.AreNotEqual(0, OrderStaging."Entry No.", 'Entry No. must be assigned');
        StoredOrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(StoredOrderStaging.Status::Pending, StoredOrderStaging.Status, 'Status');
        Assert.AreNotEqual(0DT, StoredOrderStaging."Received At", 'Received At');
        Assert.AreEqual(0, StoredOrderStaging.Attempts, 'Attempts');
    end;

    /// <summary>
    /// Given an abandoned staged order, when the operator confirms Retry Now on the list, then the order is
    /// pending again and due immediately.
    /// </summary>
    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RetryNowRequeuesAbandonedOrder()
    var
        OrderStaging: Record "CMC Order Staging";
    begin
        Initialize();
        StageWithStatus(OrderStaging, Enum::"CMC Staging Status"::Abandoned);
        LibraryVariableStorage.Enqueue(true);

        InvokeRetryNow(OrderStaging);

        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(OrderStaging.Status::Pending, OrderStaging.Status, 'Status');
        Assert.IsTrue(OrderStaging."Next Retry At" <= CurrentDateTime(), 'The order must be due immediately');
        LibraryVariableStorage.AssertEmpty();
    end;

    /// <summary>
    /// Given an abandoned staged order, when the operator declines the Retry Now confirmation, then the order is
    /// left as it was.
    /// </summary>
    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RetryNowDeclinedLeavesOrder()
    var
        OrderStaging: Record "CMC Order Staging";
    begin
        Initialize();
        StageWithStatus(OrderStaging, Enum::"CMC Staging Status"::Abandoned);
        LibraryVariableStorage.Enqueue(false);

        InvokeRetryNow(OrderStaging);

        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(OrderStaging.Status::Abandoned, OrderStaging.Status, 'Status');
        LibraryVariableStorage.AssertEmpty();
    end;

    /// <summary>
    /// Given a completed staged order, when the operator confirms Retry Now on it, then it stays completed, so a
    /// finished order cannot be pushed through intake twice.
    /// </summary>
    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RetryNowLeavesCompletedOrder()
    var
        OrderStaging: Record "CMC Order Staging";
    begin
        Initialize();
        StageWithStatus(OrderStaging, Enum::"CMC Staging Status"::Completed);
        LibraryVariableStorage.Enqueue(true);

        InvokeRetryNow(OrderStaging);

        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(OrderStaging.Status::Completed, OrderStaging.Status, 'Status');
        LibraryVariableStorage.AssertEmpty();
    end;

    /// <summary>
    /// Given one valid due staged order, when the operator runs Process Queue from the list, then it is turned
    /// into a sales document and the operator is told how many documents were created.
    /// </summary>
    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ProcessQueueReportsCreatedDocuments()
    var
        OrderStaging: Record "CMC Order Staging";
        OrderStagingList: TestPage "CMC Order Staging List";
    begin
        Initialize();
        TestLibrary.DisableSalesWarnings();
        TestLibrary.CreateStagedOrderWithLine(OrderStaging, 10);
        TestLibrary.MakeDue(OrderStaging);

        OrderStagingList.OpenView();
        OrderStagingList.ProcessQueue.Invoke();
        OrderStagingList.Close();

        Assert.IsTrue(StrPos(LibraryVariableStorage.DequeueText(), ProcessedTok) > 0, 'Process Queue message');
        OrderStaging.Get(OrderStaging."Entry No.");
        Assert.AreEqual(OrderStaging.Status::Completed, OrderStaging.Status, 'Status');
        LibraryVariableStorage.AssertEmpty();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        TestLibrary.RestoreDefaultImplementations();
        TestLibrary.ResetSetup();
        TestLibrary.DeleteAllStaging();
    end;

    local procedure StageWithStatus(var OrderStaging: Record "CMC Order Staging"; Status: Enum "CMC Staging Status")
    begin
        TestLibrary.CreateStagedOrder(OrderStaging, TestLibrary.CreateCustomerNo(), Enum::"CMC Commerce Document Type"::Order);
        OrderStaging.Status := Status;
        OrderStaging.Attempts := 5;
        OrderStaging."Next Retry At" := CurrentDateTime() + 3600000;
        OrderStaging.Modify();
    end;

    local procedure InvokeRetryNow(var OrderStaging: Record "CMC Order Staging")
    var
        OrderStagingList: TestPage "CMC Order Staging List";
    begin
        OrderStagingList.OpenView();
        OrderStagingList.GoToRecord(OrderStaging);
        OrderStagingList.RetryNow.Invoke();
        OrderStagingList.Close();
    end;
}
