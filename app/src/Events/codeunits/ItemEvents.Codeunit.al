namespace CommerceConnector.Events;

using CommerceConnector.General;
using Microsoft.Inventory.Item;

codeunit 70021 "CMC Item Events"
{
    SingleInstance = true;

    [EventSubscriber(ObjectType::Table, Database::Item, OnAfterInsertEvent, '', true, true)]
    local procedure OnAfterInsertItem(var Rec: Record Item; RunTrigger: Boolean)
    var
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        ServiceLocator.Reactions().OnItemChanged(Rec, ServiceLocator.CreatedChangeType());
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, OnAfterModifyEvent, '', true, true)]
    local procedure OnAfterModifyItem(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    var
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        ServiceLocator.Reactions().OnItemChanged(Rec, ServiceLocator.UpdatedChangeType());
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, OnAfterDeleteEvent, '', true, true)]
    local procedure OnAfterDeleteItem(var Rec: Record Item; RunTrigger: Boolean)
    var
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        ServiceLocator.Reactions().OnItemChanged(Rec, ServiceLocator.DeletedChangeType());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Category", OnAfterInsertEvent, '', true, true)]
    local procedure OnAfterInsertItemCategory(var Rec: Record "Item Category"; RunTrigger: Boolean)
    var
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        ServiceLocator.Reactions().OnItemCategoryChanged(Rec.Code, Rec.SystemId, ServiceLocator.CreatedChangeType());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Category", OnAfterModifyEvent, '', true, true)]
    local procedure OnAfterModifyItemCategory(var Rec: Record "Item Category"; var xRec: Record "Item Category"; RunTrigger: Boolean)
    var
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        ServiceLocator.Reactions().OnItemCategoryChanged(Rec.Code, Rec.SystemId, ServiceLocator.UpdatedChangeType());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Category", OnAfterDeleteEvent, '', true, true)]
    local procedure OnAfterDeleteItemCategory(var Rec: Record "Item Category"; RunTrigger: Boolean)
    var
        ServiceLocator: Codeunit "CMC Service Locator";
    begin
        ServiceLocator.Reactions().OnItemCategoryChanged(Rec.Code, Rec.SystemId, ServiceLocator.DeletedChangeType());
    end;
}
