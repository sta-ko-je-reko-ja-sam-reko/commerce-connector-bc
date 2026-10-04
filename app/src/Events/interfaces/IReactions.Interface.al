namespace CommerceConnector.Events;

using Microsoft.Inventory.Item;

interface "CMC IReactions"
{
    Access = Public;

    procedure OnItemChanged(var Item: Record Item; ChangeType: Text)
    procedure OnItemCategoryChanged(var ItemCategory: Record "Item Category"; ChangeType: Text)
    procedure RecordChange(Topic: Text; EntityId: Guid; EntityKey: Text; ChangeType: Text)
}
