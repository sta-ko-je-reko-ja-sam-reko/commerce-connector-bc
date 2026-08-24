namespace CommerceConnector.Catalogue;

using Microsoft.Inventory.Item;

query 57110 "CMC API Item Delta"
{
    QueryType = API;
    APIPublisher = 'stakojerekojasamreko';
    APIGroup = 'commerce';
    APIVersion = 'v1.0';
    EntityName = 'itemDelta';
    EntitySetName = 'itemDelta';
    Caption = 'Commerce Item Delta';
    OrderBy = ascending(changedAt), ascending(number);

    elements
    {
        dataitem(Item; Item)
        {
            column(systemId; SystemId) { Caption = 'System Id'; }
            column(changedAt; SystemModifiedAt) { Caption = 'Changed At'; }
            column(number; "No.") { Caption = 'Number'; }
            column(name; Description) { Caption = 'Name'; }
            column(nameSecondary; "Description 2") { Caption = 'Name Secondary'; }
            column(itemType; Type) { Caption = 'Item Type'; }
            column(categoryCode; "Item Category Code") { Caption = 'Category Code'; }
            column(baseUnitOfMeasure; "Base Unit of Measure") { Caption = 'Base Unit of Measure'; }
            column(salesUnitOfMeasure; "Sales Unit of Measure") { Caption = 'Sales Unit of Measure'; }
            column(listUnitPrice; "Unit Price") { Caption = 'List Unit Price'; }
            column(blocked; Blocked) { Caption = 'Blocked'; }
            column(salesBlocked; "Sales Blocked") { Caption = 'Sales Blocked'; }
            column(grossWeight; "Gross Weight") { Caption = 'Gross Weight'; }

            dataitem(ItemCategory; "Item Category")
            {
                DataItemLink = Code = Item."Item Category Code";
                SqlJoinType = LeftOuterJoin;

                column(categoryName; Description) { Caption = 'Category Name'; }
                column(categoryParent; "Parent Category") { Caption = 'Category Parent'; }
                column(categoryIndentation; Indentation) { Caption = 'Category Indentation'; }
            }
        }
    }
}
