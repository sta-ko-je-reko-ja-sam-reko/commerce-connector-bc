namespace CommerceConnector.Orders;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 57111 "CMC Order Staging Line"
{
    DataClassification = CustomerContent;
    Caption = 'Commerce Order Staging Line';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the staged order this line belongs to.';
            TableRelation = "CMC Order Staging"."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the position of the line within the staged order.';
        }
        field(5; "Line Ref"; Text[50])
        {
            Caption = 'Line Ref';
            ToolTip = 'Specifies the reference the caller assigned to this line, echoed back so the platform can correlate the result.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item ordered on this line.';
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the item variant ordered on this line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; Quantity; Decimal)
        {
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity ordered on this line.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit the quantity is expressed in.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(14; "Agreed Unit Price"; Decimal)
        {
            Caption = 'Agreed Unit Price';
            ToolTip = 'Specifies the price the customer was shown and accepted. It is compared against the price Business Central resolves before the document is created.';
            AutoFormatType = 2;
        }
        field(15; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location this line is served from.';
            TableRelation = Location;
        }
        field(16; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            ToolTip = 'Specifies the delivery date requested for this line.';
        }
    }

    keys
    {
        key(PK; "Entry No.", "Line No.") { Clustered = true; }
    }
}
