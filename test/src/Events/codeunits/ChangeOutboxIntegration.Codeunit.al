namespace CommerceConnector.Test;

using CommerceConnector.Events;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 74008 "CMC Change Outbox Integration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        TestLibrary: Codeunit "CMC Test Library";
        MissingChangeLbl: Label 'Expected a %1 change for %2 on the outbox.', Locked = true;

    /// <summary>
    /// Given publishing enabled, when an item is inserted, then a pending created entry is recorded on the item
    /// topic, carrying the item's system id and number.
    /// </summary>
    [Test]
    procedure ItemInsertRecordsCreatedChange()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        Item: Record Item;
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        Initialize();

        InsertItem(Item);

        FindChange(ChangeOutbox, Item."No.", CommerceReactions.CreatedChangeType());
        Assert.AreEqual(CommerceReactions.ItemChangedTopic(), ChangeOutbox.Topic, 'Topic');
        Assert.AreEqual(Item.SystemId, ChangeOutbox."Entity Id", 'Entity Id');
        Assert.AreEqual(ChangeOutbox.Status::Pending, ChangeOutbox.Status, 'Status');
        Assert.AreNotEqual(0DT, ChangeOutbox."Changed At", 'Changed At');
        Assert.AreNotEqual(0DT, ChangeOutbox."Next Retry At", 'Next Retry At');
    end;

    /// <summary>
    /// Given publishing enabled, when an item is modified, then an updated entry is recorded.
    /// </summary>
    [Test]
    procedure ItemModifyRecordsUpdatedChange()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        Item: Record Item;
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        Initialize();
        InsertItem(Item);

        Item.Description := 'Changed';
        Item.Modify();

        FindChange(ChangeOutbox, Item."No.", CommerceReactions.UpdatedChangeType());
    end;

    /// <summary>
    /// Given publishing enabled, when an item is deleted, then a deleted entry is recorded, so the projection can
    /// drop it.
    /// </summary>
    [Test]
    procedure ItemDeleteRecordsDeletedChange()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        Item: Record Item;
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        Initialize();
        InsertItem(Item);

        Item.Delete();

        FindChange(ChangeOutbox, Item."No.", CommerceReactions.DeletedChangeType());
    end;

    /// <summary>
    /// Given publishing enabled, when an item category is inserted, then a created entry is recorded on the
    /// category topic.
    /// </summary>
    [Test]
    procedure CategoryInsertRecordsCategoryChange()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        ItemCategory: Record "Item Category";
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        Initialize();

        ItemCategory.Init();
        ItemCategory.Code := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(ItemCategory.Code));
        ItemCategory.Insert();

        FindChange(ChangeOutbox, ItemCategory.Code, CommerceReactions.CreatedChangeType());
        Assert.AreEqual(CommerceReactions.CategoryChangedTopic(), ChangeOutbox.Topic, 'Topic');
        Assert.AreEqual(ItemCategory.SystemId, ChangeOutbox."Entity Id", 'Entity Id');
    end;

    /// <summary>
    /// Given publishing disabled in setup, when an item is inserted, then nothing is recorded.
    /// </summary>
    [Test]
    procedure DisabledPublishingRecordsNothing()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        Item: Record Item;
    begin
        Initialize();
        TestLibrary.SetPublishBusinessEvents(false);

        InsertItem(Item);

        Assert.IsTrue(ChangeOutbox.IsEmpty(), 'No change may be recorded while publishing is disabled');
    end;

    /// <summary>
    /// Given publishing enabled, when a temporary item or item category is inserted, then nothing is recorded,
    /// because a buffer record is not a catalogue change.
    /// </summary>
    [Test]
    procedure TemporaryRecordsRecordNothing()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        TempItem: Record Item temporary;
        TempItemCategory: Record "Item Category" temporary;
    begin
        Initialize();

        TempItem.Init();
        TempItem."No." := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(TempItem."No."));
        TempItem.Insert();
        TempItemCategory.Init();
        TempItemCategory.Code := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(TempItemCategory.Code));
        TempItemCategory.Insert();

        Assert.IsTrue(ChangeOutbox.IsEmpty(), 'A temporary record must not reach the outbox');
    end;

    /// <summary>
    /// Given values longer than the outbox fields, when a change is recorded directly, then they are truncated to
    /// fit rather than failing the transaction that caused the change.
    /// </summary>
    [Test]
    procedure RecordChangeTruncatesLongValues()
    var
        ChangeOutbox: Record "CMC Change Outbox";
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        Initialize();

        CommerceReactions.RecordChange(PadStr('', 150, 't'), CreateGuid(), PadStr('', 150, 'k'), PadStr('', 30, 'c'));

        ChangeOutbox.FindFirst();
        Assert.AreEqual(MaxStrLen(ChangeOutbox.Topic), StrLen(ChangeOutbox.Topic), 'Topic length');
        Assert.AreEqual(MaxStrLen(ChangeOutbox."Entity Key"), StrLen(ChangeOutbox."Entity Key"), 'Entity Key length');
        Assert.AreEqual(MaxStrLen(ChangeOutbox."Change Type"), StrLen(ChangeOutbox."Change Type"), 'Change Type length');
    end;

    /// <summary>
    /// Given the default reactions, when the topics are read, then they are the channel names the integration
    /// layer subscribes to.
    /// </summary>
    [Test]
    procedure TopicsMatchIntegrationContract()
    var
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        Assert.AreEqual('catalogue.item.changed', CommerceReactions.ItemChangedTopic(), 'Item topic');
        Assert.AreEqual('catalogue.category.changed', CommerceReactions.CategoryChangedTopic(), 'Category topic');
    end;

    local procedure Initialize()
    begin
        TestLibrary.RestoreDefaultImplementations();
        TestLibrary.ResetSetup();
        TestLibrary.DeleteAllOutbox();
    end;

    local procedure InsertItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(Item."No."));
        Item.Insert();
    end;

    local procedure FindChange(var ChangeOutbox: Record "CMC Change Outbox"; EntityKey: Text; ChangeType: Text)
    begin
        ChangeOutbox.SetRange("Entity Key", EntityKey);
        ChangeOutbox.SetRange("Change Type", ChangeType);
        Assert.IsTrue(ChangeOutbox.FindFirst(), StrSubstNo(MissingChangeLbl, ChangeType, EntityKey));
    end;
}
