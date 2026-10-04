namespace CommerceConnector.Test;

using CommerceConnector.Setup;
using System.TestLibraries.Utilities;

codeunit 74001 "CMC Commerce Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PageSizeTooLargeTok: Label 'catalogue page size cannot exceed', Locked = true;
        BulkCapTooLargeTok: Label 'bulk line cap cannot exceed', Locked = true;
        ThresholdTooHighTok: Label 'low stock threshold cannot exceed', Locked = true;
        TestFieldTok: Label 'TestField', Locked = true;

    /// <summary>
    /// Given a new setup record, when it is initialised, then every field carries the shipped default.
    /// </summary>
    [Test]
    procedure NewSetupCarriesShippedDefaults()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
    begin
        TempCommerceSetup.Init();

        Assert.AreEqual(500, TempCommerceSetup."Catalogue Page Size", 'Catalogue Page Size');
        Assert.AreEqual(100, TempCommerceSetup."Bulk Line Cap", 'Bulk Line Cap');
        Assert.AreEqual(5, TempCommerceSetup."Low Stock Threshold", 'Low Stock Threshold');
        Assert.AreEqual(5, TempCommerceSetup."Order Intake Max Attempts", 'Order Intake Max Attempts');
        Assert.AreEqual(60, TempCommerceSetup."Retry Backoff Seconds", 'Retry Backoff Seconds');
        Assert.AreEqual(90, TempCommerceSetup."Staging Retention Days", 'Staging Retention Days');
        Assert.IsTrue(TempCommerceSetup."Publish Business Events", 'Publish Business Events');
    end;

    /// <summary>
    /// Given the default logic, when the contract limits are read, then they match the published contract.
    /// </summary>
    [Test]
    procedure ContractLimitsMatchPublishedContract()
    var
        CommerceSetupLogic: Codeunit "CMC Commerce Setup Logic";
    begin
        Assert.AreEqual(1000, CommerceSetupLogic.MaxCataloguePageSize(), 'Max catalogue page size');
        Assert.AreEqual(100, CommerceSetupLogic.MaxBulkLineCap(), 'Max bulk line cap');
        Assert.AreEqual(9999, CommerceSetupLogic.MaxLowStockThreshold(), 'Max low stock threshold');
    end;

    /// <summary>
    /// Given a setup record, when the page size is set to the contract maximum, then it is accepted.
    /// </summary>
    [Test]
    procedure PageSizeAtContractMaximumIsAccepted()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
    begin
        TempCommerceSetup.Validate("Catalogue Page Size", 1000);

        Assert.AreEqual(1000, TempCommerceSetup."Catalogue Page Size", 'Catalogue Page Size');
    end;

    /// <summary>
    /// Given a setup record, when the page size is set one above the contract maximum, then it is rejected.
    /// </summary>
    [Test]
    procedure PageSizeAboveContractMaximumIsRejected()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
    begin
        asserterror TempCommerceSetup.Validate("Catalogue Page Size", 1001);

        Assert.ExpectedError(PageSizeTooLargeTok);
    end;

    /// <summary>
    /// Given a setup record, when the bulk line cap is set to the contract maximum, then it is accepted.
    /// </summary>
    [Test]
    procedure BulkLineCapAtContractMaximumIsAccepted()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
    begin
        TempCommerceSetup.Validate("Bulk Line Cap", 100);

        Assert.AreEqual(100, TempCommerceSetup."Bulk Line Cap", 'Bulk Line Cap');
    end;

    /// <summary>
    /// Given a setup record, when the bulk line cap is set one above the contract maximum, then it is rejected.
    /// </summary>
    [Test]
    procedure BulkLineCapAboveContractMaximumIsRejected()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
    begin
        asserterror TempCommerceSetup.Validate("Bulk Line Cap", 101);

        Assert.ExpectedError(BulkCapTooLargeTok);
    end;

    /// <summary>
    /// Given a setup record, when the low stock threshold is set to the maximum, then it is accepted.
    /// </summary>
    [Test]
    procedure LowStockThresholdAtMaximumIsAccepted()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
    begin
        TempCommerceSetup.Validate("Low Stock Threshold", 9999);

        Assert.AreEqual(9999, TempCommerceSetup."Low Stock Threshold", 'Low Stock Threshold');
    end;

    /// <summary>
    /// Given a setup record, when the low stock threshold is set just above the maximum, then it is rejected.
    /// </summary>
    [Test]
    procedure LowStockThresholdAboveMaximumIsRejected()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
    begin
        asserterror TempCommerceSetup.Validate("Low Stock Threshold", 9999.5);

        Assert.ExpectedError(ThresholdTooHighTok);
    end;

    /// <summary>
    /// Given a setup record with the defaults, when the insert logic runs, then it accepts the record unchanged.
    /// </summary>
    [Test]
    procedure InsertWithDefaultsIsAccepted()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
        CommerceSetupLogic: Codeunit "CMC Commerce Setup Logic";
    begin
        TempCommerceSetup.Init();

        CommerceSetupLogic.Trigger_OnInsert(TempCommerceSetup);

        Assert.AreEqual(500, TempCommerceSetup."Catalogue Page Size", 'The insert logic must not change the record');
    end;

    /// <summary>
    /// Given a setup record without a catalogue page size, when the insert logic runs, then it is rejected.
    /// </summary>
    [Test]
    procedure InsertWithoutPageSizeIsRejected()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
        CommerceSetupLogic: Codeunit "CMC Commerce Setup Logic";
    begin
        TempCommerceSetup.Init();
        TempCommerceSetup."Catalogue Page Size" := 0;

        asserterror CommerceSetupLogic.Trigger_OnInsert(TempCommerceSetup);

        Assert.ExpectedErrorCode(TestFieldTok);
    end;

    /// <summary>
    /// Given a setup record without a bulk line cap, when the insert logic runs, then it is rejected.
    /// </summary>
    [Test]
    procedure InsertWithoutBulkLineCapIsRejected()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
        CommerceSetupLogic: Codeunit "CMC Commerce Setup Logic";
    begin
        TempCommerceSetup.Init();
        TempCommerceSetup."Bulk Line Cap" := 0;

        asserterror CommerceSetupLogic.Trigger_OnInsert(TempCommerceSetup);

        Assert.ExpectedErrorCode(TestFieldTok);
    end;

    /// <summary>
    /// Given an injected fake, when the three validated fields are set beyond the contract limits, then each
    /// validation reaches the fake and none reaches the default logic.
    /// </summary>
    [Test]
    procedure FieldValidationDelegatesToInjectedLogic()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
        FakeCommerceSetup: Codeunit "CMC Fake Commerce Setup";
    begin
        TempCommerceSetup.Define(FakeCommerceSetup);

        TempCommerceSetup.Validate("Catalogue Page Size", 5000);
        TempCommerceSetup.Validate("Bulk Line Cap", 500);
        TempCommerceSetup.Validate("Low Stock Threshold", 20000);

        Assert.AreEqual(3, FakeCommerceSetup.ValidateCallCount(), 'Validations delegated to the fake');
        Assert.AreEqual(5000, TempCommerceSetup."Catalogue Page Size", 'Catalogue Page Size');
    end;

    /// <summary>
    /// Given an injected fake, when a record the default logic would reject is inserted, then the insert reaches
    /// the fake instead.
    /// </summary>
    [Test]
    procedure InsertTriggerDelegatesToInjectedLogic()
    var
        TempCommerceSetup: Record "CMC Commerce Setup" temporary;
        FakeCommerceSetup: Codeunit "CMC Fake Commerce Setup";
    begin
        TempCommerceSetup.Define(FakeCommerceSetup);
        TempCommerceSetup.Init();
        TempCommerceSetup."Catalogue Page Size" := 0;

        TempCommerceSetup.Insert(true);

        Assert.AreEqual(1, FakeCommerceSetup.InsertCallCount(), 'Insert delegated to the fake');
    end;
}
