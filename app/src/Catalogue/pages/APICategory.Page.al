namespace CommerceConnector.Catalogue;

using Microsoft.Inventory.Item;

page 70010 "CMC API Category"
{
    PageType = API;
    APIPublisher = 'stakojerekojasamreko';
    APIGroup = 'commerce';
    APIVersion = 'v1.0';
    EntityName = 'category';
    EntitySetName = 'categories';
    EntityCaption = 'Category';
    EntitySetCaption = 'Categories';
    SourceTable = "Item Category";
    DelayedInsert = true;
    Editable = false;
    Extensible = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId) { Caption = 'System Id'; Editable = false; }
                field(code; Rec.Code) { Caption = 'Code'; }
                field(name; Rec.Description) { Caption = 'Name'; }
                field(parentCategory; Rec."Parent Category") { Caption = 'Parent Category'; }
                field(indentation; Rec.Indentation) { Caption = 'Indentation'; }
                field(hasChildren; Rec."Has Children") { Caption = 'Has Children'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; }
            }
        }
    }
}
