namespace CommerceConnector.Pricing;

using CommerceConnector.General;
using Microsoft.Inventory.Item;

table 57130 "CMC Price Request Line"
{
    TableType = Temporary;
    DataClassification = CustomerContent;
    Caption = 'Commerce Price Request Line';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the position of the line within the request.';
        }
        field(5; "Line Ref"; Text[50])
        {
            Caption = 'Line Ref';
            ToolTip = 'Specifies the reference the caller assigned to this line, echoed back so the platform can correlate the result.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item the price is requested for.';
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the item variant the price is requested for.';
        }
        field(12; Quantity; Decimal)
        {
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity the price is requested for, which decides which volume break applies.';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit the quantity is expressed in.';
        }
        field(14; "Requested Date"; Date)
        {
            Caption = 'Requested Date';
            ToolTip = 'Specifies the date the price is requested for, which decides which campaign is active.';
        }
        field(20; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            ToolTip = 'Specifies the resolved customer price.';
            AutoFormatType = 2;
        }
        field(21; "List Price"; Decimal)
        {
            Caption = 'List Price';
            ToolTip = 'Specifies the undiscounted price, for display alongside the resolved price.';
            AutoFormatType = 2;
        }
        field(22; "Discount Percent"; Decimal)
        {
            Caption = 'Discount Percent';
            ToolTip = 'Specifies the discount the resolved price represents against the list price.';
            DecimalPlaces = 0 : 5;
        }
        field(23; "Price Source"; Enum "CMC Price Source")
        {
            Caption = 'Price Source';
            ToolTip = 'Specifies which commercial rule produced the resolved price.';
        }
        field(24; Unavailable; Boolean)
        {
            Caption = 'Unavailable';
            ToolTip = 'Specifies that no price could be resolved, which means the line is not sellable online.';
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}
