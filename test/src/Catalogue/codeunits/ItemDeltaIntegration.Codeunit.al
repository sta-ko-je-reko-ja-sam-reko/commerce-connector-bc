namespace CommerceConnector.Test;

using CommerceConnector.Catalogue;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 74009 "CMC Item Delta Integration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        TestLibrary: Codeunit "CMC Test Library";

    /// <summary>
    /// Given an item in a category, when the delta feed is read for it, then the row carries the item columns and
    /// the category joined to it.
    /// </summary>
    [Test]
    procedure ItemRowCarriesJoinedCategory()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemDelta: Query "CMC API Item Delta";
    begin
        TestLibrary.RestoreDefaultImplementations();
        ItemCategory.Init();
        ItemCategory.Code := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(ItemCategory.Code));
        ItemCategory.Description := 'Delta category';
        ItemCategory.Insert();
        InsertItem(Item, CopyStr(Any.AlphanumericText(20), 1, 20), ItemCategory.Code, 12.5);

        ItemDelta.SetRange(number, Item."No.");
        ItemDelta.Open();

        Assert.IsTrue(ItemDelta.Read(), 'The item must be in the feed');
        Assert.AreEqual(Item.SystemId, ItemDelta.systemId, 'systemId');
        Assert.AreEqual(Item.Description, ItemDelta.name, 'name');
        Assert.AreEqual(12.5, ItemDelta.listUnitPrice, 'listUnitPrice');
        Assert.AreEqual(ItemCategory.Code, ItemDelta.categoryCode, 'categoryCode');
        Assert.AreEqual(ItemCategory.Description, ItemDelta.categoryName, 'categoryName');
        Assert.IsFalse(ItemDelta.Read(), 'The join must not duplicate the item');
        ItemDelta.Close();
    end;

    /// <summary>
    /// Given an item without a category, when the delta feed is read for it, then the item is still returned,
    /// because the category join is a left outer join.
    /// </summary>
    [Test]
    procedure ItemWithoutCategoryIsReturned()
    var
        Item: Record Item;
        ItemDelta: Query "CMC API Item Delta";
    begin
        TestLibrary.RestoreDefaultImplementations();
        InsertItem(Item, CopyStr(Any.AlphanumericText(20), 1, 20), '', 1);

        ItemDelta.SetRange(number, Item."No.");
        ItemDelta.Open();

        Assert.IsTrue(ItemDelta.Read(), 'An item without a category must be in the feed');
        Assert.AreEqual('', ItemDelta.categoryName, 'categoryName');
        ItemDelta.Close();
    end;

    /// <summary>
    /// Given several items, when the delta feed is read, then rows come ordered by change time and then by item
    /// number, the order the integration layer's keyset cursor relies on.
    /// </summary>
    [Test]
    procedure FeedIsOrderedByChangeTimeThenNumber()
    var
        Item: Record Item;
        ItemDelta: Query "CMC API Item Delta";
        Prefix: Code[10];
        PreviousChangedAt: DateTime;
        PreviousNumber: Code[20];
        Rows: Integer;
    begin
        TestLibrary.RestoreDefaultImplementations();
        Prefix := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(Prefix));
        InsertItem(Item, Prefix + '3', '', 1);
        InsertItem(Item, Prefix + '1', '', 1);
        InsertItem(Item, Prefix + '2', '', 1);

        ItemDelta.SetFilter(number, Prefix + '*');
        ItemDelta.Open();
        PreviousChangedAt := 0DT;
        PreviousNumber := '';
        while ItemDelta.Read() do begin
            Rows += 1;
            Assert.IsTrue(ItemDelta.changedAt >= PreviousChangedAt, 'Rows must be ordered by changedAt');
            if ItemDelta.changedAt = PreviousChangedAt then
                Assert.IsTrue(ItemDelta.number > PreviousNumber, 'Rows sharing a changedAt must be ordered by number');
            PreviousChangedAt := ItemDelta.changedAt;
            PreviousNumber := ItemDelta.number;
        end;
        ItemDelta.Close();

        Assert.AreEqual(3, Rows, 'Rows read');
    end;

    local procedure InsertItem(var Item: Record Item; ItemNo: Code[20]; CategoryCode: Code[20]; UnitPrice: Decimal)
    begin
        Item.Init();
        Item."No." := ItemNo;
        Item.Description := ItemNo;
        Item."Item Category Code" := CategoryCode;
        Item."Unit Price" := UnitPrice;
        Item.Insert();
    end;
}
