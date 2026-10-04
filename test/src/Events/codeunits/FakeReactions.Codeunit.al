namespace CommerceConnector.Test;

using CommerceConnector.Events;
using Microsoft.Inventory.Item;

codeunit 74052 "CMC Fake Reactions" implements "CMC IReactions"
{
    Access = Public;

    var
        ItemCalls: Integer;
        CategoryCalls: Integer;
        RecordChangeCalls: Integer;
        LastEntityKey: Text;
        LastChangeType: Text;

    procedure OnItemChanged(var Item: Record Item; ChangeType: Text)
    begin
        ItemCalls += 1;
        LastEntityKey := Item."No.";
        LastChangeType := ChangeType;
    end;

    procedure OnItemCategoryChanged(var ItemCategory: Record "Item Category"; ChangeType: Text)
    begin
        CategoryCalls += 1;
        LastEntityKey := ItemCategory.Code;
        LastChangeType := ChangeType;
    end;

    procedure RecordChange(Topic: Text; EntityId: Guid; EntityKey: Text; ChangeType: Text)
    begin
        RecordChangeCalls += 1;
        LastEntityKey := EntityKey;
        LastChangeType := ChangeType;
    end;

    /// <summary>
    /// Returns how many item changes reached this fake.
    /// </summary>
    procedure ItemCallCount(): Integer
    begin
        exit(ItemCalls);
    end;

    /// <summary>
    /// Returns how many item category changes reached this fake.
    /// </summary>
    procedure CategoryCallCount(): Integer
    begin
        exit(CategoryCalls);
    end;

    /// <summary>
    /// Returns how many direct RecordChange calls reached this fake.
    /// </summary>
    procedure RecordChangeCallCount(): Integer
    begin
        exit(RecordChangeCalls);
    end;

    /// <summary>
    /// Returns the business key of the most recent change this fake received.
    /// </summary>
    procedure LastKey(): Text
    begin
        exit(LastEntityKey);
    end;

    /// <summary>
    /// Returns the change type of the most recent change this fake received.
    /// </summary>
    procedure LastType(): Text
    begin
        exit(LastChangeType);
    end;
}
