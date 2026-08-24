namespace CommerceConnector.Events;

using Microsoft.Inventory.Item;

interface "CMC IReactions"
{
    Access = Public;

    procedure OnItemChanged(var Item: Record Item; ChangeType: Text)
    procedure OnItemCategoryChanged(CategoryCode: Code[20]; CategoryId: Guid; ChangeType: Text)
    procedure RecordChange(Topic: Text; EntityId: Guid; EntityKey: Text; ChangeType: Text)
}
