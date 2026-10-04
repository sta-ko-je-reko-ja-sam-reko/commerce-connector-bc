namespace CommerceConnector.Test;

using CommerceConnector.Setup;
using System.TestLibraries.Utilities;

codeunit 74002 "CMC Commerce Setup Integration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PageSizeTooLargeTok: Label 'catalogue page size cannot exceed', Locked = true;

    /// <summary>
    /// Given no setup record, when GetSetup is called, then the record is created with the shipped defaults.
    /// </summary>
    [Test]
    procedure GetSetupCreatesMissingRecordWithDefaults()
    var
        CommerceSetup: Record "CMC Commerce Setup";
        StoredCommerceSetup: Record "CMC Commerce Setup";
    begin
        CommerceSetup.DeleteAll();

        CommerceSetup.GetSetup();

        Assert.IsTrue(StoredCommerceSetup.Get(), 'GetSetup must persist the setup record');
        Assert.AreEqual(500, StoredCommerceSetup."Catalogue Page Size", 'Catalogue Page Size');
        Assert.AreEqual(5, StoredCommerceSetup."Order Intake Max Attempts", 'Order Intake Max Attempts');
    end;

    /// <summary>
    /// Given a setup record with changed values, when GetSetup is called, then the stored values are returned
    /// rather than replaced by defaults.
    /// </summary>
    [Test]
    procedure GetSetupKeepsExistingRecord()
    var
        CommerceSetup: Record "CMC Commerce Setup";
        ReadCommerceSetup: Record "CMC Commerce Setup";
    begin
        CommerceSetup.DeleteAll();
        CommerceSetup.GetSetup();
        CommerceSetup."Retry Backoff Seconds" := 7;
        CommerceSetup.Modify();

        ReadCommerceSetup.GetSetup();

        Assert.AreEqual(7, ReadCommerceSetup."Retry Backoff Seconds", 'Retry Backoff Seconds');
        Assert.AreEqual(1, ReadCommerceSetup.Count(), 'Setup is a singleton');
    end;

    /// <summary>
    /// Given no setup record, when the setup page is opened, then the record is created so the page shows the
    /// defaults instead of an empty card.
    /// </summary>
    [Test]
    procedure SetupPageCreatesMissingRecord()
    var
        CommerceSetup: Record "CMC Commerce Setup";
        CommerceSetupPage: TestPage "CMC Commerce Setup";
    begin
        CommerceSetup.DeleteAll();

        CommerceSetupPage.OpenEdit();

        CommerceSetupPage."Catalogue Page Size".AssertEquals(500);
        CommerceSetupPage.Close();
        Assert.IsFalse(CommerceSetup.IsEmpty(), 'Opening the page must create the setup record');
    end;

    /// <summary>
    /// Given the setup page, when a page size above the contract maximum is entered, then the page rejects it.
    /// </summary>
    [Test]
    procedure SetupPageRejectsPageSizeAboveContract()
    var
        CommerceSetup: Record "CMC Commerce Setup";
        CommerceSetupPage: TestPage "CMC Commerce Setup";
    begin
        CommerceSetup.DeleteAll();
        CommerceSetupPage.OpenEdit();

        asserterror CommerceSetupPage."Catalogue Page Size".SetValue(1001);

        Assert.ExpectedError(PageSizeTooLargeTok);
    end;
}
