namespace CommerceConnector.Test;

using CommerceConnector.Events;
using CommerceConnector.General;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 74007 "CMC Service Locator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        TestLibrary: Codeunit "CMC Test Library";

    /// <summary>
    /// Given the shipped implementations, when a change is recorded through the located reactions, then it lands
    /// on the outbox, which only the default implementation writes.
    /// </summary>
    [Test]
    procedure LocatedDefaultReactionsWriteOutbox()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        TestLibrary.RestoreDefaultImplementations();
        TestLibrary.ResetSetup();
        TestLibrary.DeleteAllOutbox();

        ServiceLocator.Reactions().RecordChange('catalogue.item.changed', CreateGuid(), 'KEY', ServiceLocator.CreatedChangeType());

        ChangeOutbox.SetRange("Entity Key", 'KEY');
        Assert.IsFalse(ChangeOutbox.IsEmpty(), 'The default reactions must record the change');
    end;

    /// <summary>
    /// Given a fake order intake injected into the locator, when the located intake is called, then the call
    /// reaches the fake with its arguments.
    /// </summary>
    [Test]
    procedure InjectedOrderIntakeIsReturned()
    var
        FakeOrderIntake: Codeunit "CMC Fake Order Intake";
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        TestLibrary.RestoreDefaultImplementations();
        ServiceLocator.ImplementOrderIntake(FakeOrderIntake);

        ServiceLocator.OrderIntake().ProcessPending(7);
        TestLibrary.RestoreDefaultImplementations();

        Assert.AreEqual(1, FakeOrderIntake.ProcessPendingCallCount(), 'ProcessPending calls');
        Assert.AreEqual(7, FakeOrderIntake.LastRequestedBatchSize(), 'Batch size');
    end;

    /// <summary>
    /// Given a fake injected into one locator variable, when another variable asks for the implementation, then
    /// it gets the same fake, because the locator is single instance for the session.
    /// </summary>
    [Test]
    procedure InjectionIsSharedAcrossTheSession()
    var
        FakeReactions: Codeunit "CMC Fake Reactions";
        InjectingServiceLocator: Codeunit "CMC Service Locator";
        ResolvingServiceLocator: Codeunit "CMC Service Locator";
    begin
        TestLibrary.RestoreDefaultImplementations();
        InjectingServiceLocator.ImplementReactions(FakeReactions);

        ResolvingServiceLocator.Reactions().RecordChange('', CreateGuid(), 'KEY', 'created');
        TestLibrary.RestoreDefaultImplementations();

        Assert.AreEqual(1, FakeReactions.RecordChangeCallCount(), 'RecordChange calls');
        Assert.AreEqual('KEY', FakeReactions.LastKey(), 'Entity key');
    end;

    /// <summary>
    /// Given the locator, when the change type names are read, then they match the ones the default reactions
    /// record on the outbox.
    /// </summary>
    [Test]
    procedure ChangeTypesMatchDefaultReactions()
    var
        CommerceReactions: Codeunit "CMC Commerce Reactions";
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        Assert.AreEqual('created', ServiceLocator.CreatedChangeType(), 'Created');
        Assert.AreEqual('updated', ServiceLocator.UpdatedChangeType(), 'Updated');
        Assert.AreEqual('deleted', ServiceLocator.DeletedChangeType(), 'Deleted');
        Assert.AreEqual(CommerceReactions.CreatedChangeType(), ServiceLocator.CreatedChangeType(), 'Created matches');
    end;

    /// <summary>
    /// Given a fake reactions implementation, when an item is inserted, modified and deleted, then the subscriber
    /// proxy forwards each change to the fake with the matching change type, and nothing reaches the outbox.
    /// </summary>
    [Test]
    procedure ItemChangesReachInjectedReactions()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        Item: Record Item;
        FakeReactions: Codeunit "CMC Fake Reactions";
        ServiceLocator: Codeunit "CMC Service Locator";
        ItemNo: Code[20];
        Types: List of [Text];
    begin
        TestLibrary.RestoreDefaultImplementations();
        TestLibrary.DeleteAllOutbox();
        ItemNo := CopyStr(Any.AlphanumericText(20), 1, 20);
        ServiceLocator.ImplementReactions(FakeReactions);

        Item.Init();
        Item."No." := ItemNo;
        Item.Insert();
        Types.Add(FakeReactions.LastType());
        Item.Description := 'Changed';
        Item.Modify();
        Types.Add(FakeReactions.LastType());
        Item.Delete();
        Types.Add(FakeReactions.LastType());
        TestLibrary.RestoreDefaultImplementations();

        Assert.AreEqual(3, FakeReactions.ItemCallCount(), 'Item changes forwarded');
        Assert.AreEqual(ItemNo, FakeReactions.LastKey(), 'Item No.');
        Assert.AreEqual('created', Types.Get(1), 'Insert change type');
        Assert.AreEqual('updated', Types.Get(2), 'Modify change type');
        Assert.AreEqual('deleted', Types.Get(3), 'Delete change type');
        Assert.IsTrue(ChangeOutbox.IsEmpty(), 'The default reactions must not have run');
    end;

    /// <summary>
    /// Given a fake reactions implementation, when an item category is inserted and deleted, then the subscriber
    /// proxy forwards both changes to the fake.
    /// </summary>
    [Test]
    procedure CategoryChangesReachInjectedReactions()
    var
        ItemCategory: Record "Item Category";
        FakeReactions: Codeunit "CMC Fake Reactions";
        ServiceLocator: Codeunit "CMC Service Locator";
        CategoryCode: Code[20];
    begin
        TestLibrary.RestoreDefaultImplementations();
        CategoryCode := CopyStr(Any.AlphanumericText(20), 1, 20);
        ServiceLocator.ImplementReactions(FakeReactions);

        ItemCategory.Init();
        ItemCategory.Code := CategoryCode;
        ItemCategory.Insert();
        ItemCategory.Delete();
        TestLibrary.RestoreDefaultImplementations();

        Assert.AreEqual(2, FakeReactions.CategoryCallCount(), 'Category changes forwarded');
        Assert.AreEqual(CategoryCode, FakeReactions.LastKey(), 'Category code');
        Assert.AreEqual('deleted', FakeReactions.LastType(), 'Last change type');
    end;
}
