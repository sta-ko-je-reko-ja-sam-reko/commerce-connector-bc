namespace CommerceConnector.Setup;

page 57100 "CMC Commerce Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "CMC Commerce Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Commerce Setup';

    layout
    {
        area(Content)
        {
            group(Feeds)
            {
                Caption = 'Feeds';

                field("Catalogue Page Size"; Rec."Catalogue Page Size") { }
                field("Bulk Line Cap"; Rec."Bulk Line Cap") { }
                field("Low Stock Threshold"; Rec."Low Stock Threshold") { }
            }
            group(OrderIntake)
            {
                Caption = 'Order Intake';

                field("Order Intake Max Attempts"; Rec."Order Intake Max Attempts") { }
                field("Retry Backoff Seconds"; Rec."Retry Backoff Seconds") { }
                field("Staging Retention Days"; Rec."Staging Retention Days") { }
            }
            group(Events)
            {
                Caption = 'Events';

                field("Publish Business Events"; Rec."Publish Business Events") { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
