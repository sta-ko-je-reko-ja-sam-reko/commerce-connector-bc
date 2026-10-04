namespace CommerceConnector.Events;

using CommerceConnector.General;
using CommerceConnector.Setup;
using Microsoft.Inventory.Item;

codeunit 70020 "CMC Commerce Reactions" implements "CMC IReactions"
{
    Access = Public;
    Permissions = tabledata "CMC Change Outbox" = ri;

    procedure OnItemChanged(var Item: Record Item; ChangeType: Text)
    begin
        if Item.IsTemporary() then
            exit;
        RecordChange(ItemChangedTopic(), Item.SystemId, Item."No.", ChangeType);
    end;

    procedure OnItemCategoryChanged(var ItemCategory: Record "Item Category"; ChangeType: Text)
    begin
        if ItemCategory.IsTemporary() then
            exit;
        RecordChange(CategoryChangedTopic(), ItemCategory.SystemId, ItemCategory.Code, ChangeType);
    end;

    /// <summary>
    /// Records one change on the outbox so the integration layer can collect it.
    /// </summary>
    /// <param name="Topic">The channel the change belongs to.</param>
    /// <param name="EntityId">The system identifier of the changed record.</param>
    /// <param name="EntityKey">The business key of the changed record.</param>
    /// <param name="ChangeType">Whether the record was created, updated, blocked or deleted.</param>
    procedure RecordChange(Topic: Text; EntityId: Guid; EntityKey: Text; ChangeType: Text)
    var
        ChangeOutbox: Record "CMC Change Outbox";
        CommerceSetup: Record "CMC Commerce Setup";
    begin
        CommerceSetup.GetSetup();
        if not CommerceSetup."Publish Business Events" then
            exit;

        ChangeOutbox.Init();
        ChangeOutbox.Topic := CopyStr(Topic, 1, MaxStrLen(ChangeOutbox.Topic));
        ChangeOutbox."Entity Id" := EntityId;
        ChangeOutbox."Entity Key" := CopyStr(EntityKey, 1, MaxStrLen(ChangeOutbox."Entity Key"));
        ChangeOutbox."Change Type" := CopyStr(ChangeType, 1, MaxStrLen(ChangeOutbox."Change Type"));
        ChangeOutbox."Changed At" := CurrentDateTime();
        ChangeOutbox.Status := ChangeOutbox.Status::Pending;
        ChangeOutbox."Next Retry At" := CurrentDateTime();
        ChangeOutbox.Insert(true);
    end;

    /// <summary>
    /// Returns the topic catalogue item changes are published on.
    /// </summary>
    procedure ItemChangedTopic(): Text
    begin
        exit('catalogue.item.changed');
    end;

    /// <summary>
    /// Returns the topic category changes are published on.
    /// </summary>
    procedure CategoryChangedTopic(): Text
    begin
        exit('catalogue.category.changed');
    end;

    /// <summary>
    /// Returns the change type recorded when a record is created.
    /// </summary>
    procedure CreatedChangeType(): Text
    begin
        exit('created');
    end;

    /// <summary>
    /// Returns the change type recorded when a record is updated.
    /// </summary>
    procedure UpdatedChangeType(): Text
    begin
        exit('updated');
    end;

    /// <summary>
    /// Returns the change type recorded when a record is removed.
    /// </summary>
    procedure DeletedChangeType(): Text
    begin
        exit('deleted');
    end;
}
