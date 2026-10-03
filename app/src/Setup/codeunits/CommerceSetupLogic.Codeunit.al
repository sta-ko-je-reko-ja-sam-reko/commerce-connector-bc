namespace CommerceConnector.Setup;

codeunit 70001 "CMC Commerce Setup Logic" implements "CMC ICommerceSetup"
{
    Access = Public;

    var
        PageSizeTooLargeErr: Label 'The catalogue page size cannot exceed %1. Larger pages do not complete faster and make a retry more expensive.', Comment = '%1 = maximum page size';
        BulkCapTooLargeErr: Label 'The bulk line cap cannot exceed %1, which is the limit the published contract commits to.', Comment = '%1 = maximum line cap';
        ThresholdTooHighErr: Label 'The low stock threshold cannot exceed %1.', Comment = '%1 = maximum threshold';

    procedure Trigger_OnInsert(var CommerceSetup: Record "CMC Commerce Setup")
    begin
        CommerceSetup.TestField("Catalogue Page Size");
        CommerceSetup.TestField("Bulk Line Cap");
    end;

    procedure Validate_CataloguePageSize(var CommerceSetup: Record "CMC Commerce Setup")
    begin
        if CommerceSetup."Catalogue Page Size" > MaxCataloguePageSize() then
            Error(PageSizeTooLargeErr, MaxCataloguePageSize());
    end;

    procedure Validate_BulkLineCap(var CommerceSetup: Record "CMC Commerce Setup")
    begin
        if CommerceSetup."Bulk Line Cap" > MaxBulkLineCap() then
            Error(BulkCapTooLargeErr, MaxBulkLineCap());
    end;

    procedure Validate_LowStockThreshold(var CommerceSetup: Record "CMC Commerce Setup")
    begin
        if CommerceSetup."Low Stock Threshold" > MaxLowStockThreshold() then
            Error(ThresholdTooHighErr, MaxLowStockThreshold());
    end;

    /// <summary>
    /// Returns the largest catalogue page the published contract allows.
    /// </summary>
    procedure MaxCataloguePageSize(): Integer
    begin
        exit(1000);
    end;

    /// <summary>
    /// Returns the largest number of lines a bulk price or availability request may carry.
    /// </summary>
    procedure MaxBulkLineCap(): Integer
    begin
        exit(100);
    end;

    /// <summary>
    /// Returns the largest quantity that may be configured as the low stock boundary.
    /// </summary>
    procedure MaxLowStockThreshold(): Decimal
    begin
        exit(9999);
    end;
}
