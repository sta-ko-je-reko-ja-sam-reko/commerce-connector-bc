namespace CommerceConnector.Setup;

interface "CMC ICommerceSetup"
{
    Access = Public;

    procedure Trigger_OnInsert(var CommerceSetup: Record "CMC Commerce Setup")
    procedure Validate_CataloguePageSize(var CommerceSetup: Record "CMC Commerce Setup")
    procedure Validate_BulkLineCap(var CommerceSetup: Record "CMC Commerce Setup")
    procedure Validate_LowStockThreshold(var CommerceSetup: Record "CMC Commerce Setup")
}
