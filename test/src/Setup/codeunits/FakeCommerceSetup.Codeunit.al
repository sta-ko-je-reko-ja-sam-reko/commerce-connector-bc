namespace CommerceConnector.Test;

using CommerceConnector.Setup;

codeunit 74050 "CMC Fake Commerce Setup" implements "CMC ICommerceSetup"
{
    Access = Public;

    var
        OnInsertCalls: Integer;
        ValidateCalls: Integer;

    procedure Trigger_OnInsert(var CommerceSetup: Record "CMC Commerce Setup")
    begin
        OnInsertCalls += 1;
    end;

    procedure Validate_CataloguePageSize(var CommerceSetup: Record "CMC Commerce Setup")
    begin
        ValidateCalls += 1;
    end;

    procedure Validate_BulkLineCap(var CommerceSetup: Record "CMC Commerce Setup")
    begin
        ValidateCalls += 1;
    end;

    procedure Validate_LowStockThreshold(var CommerceSetup: Record "CMC Commerce Setup")
    begin
        ValidateCalls += 1;
    end;

    /// <summary>
    /// Returns how many times the insert trigger delegated to this fake.
    /// </summary>
    procedure InsertCallCount(): Integer
    begin
        exit(OnInsertCalls);
    end;

    /// <summary>
    /// Returns how many field validations delegated to this fake.
    /// </summary>
    procedure ValidateCallCount(): Integer
    begin
        exit(ValidateCalls);
    end;
}
