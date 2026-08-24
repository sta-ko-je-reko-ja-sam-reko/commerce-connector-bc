namespace CommerceConnector.Availability;

using CommerceConnector.General;

interface "CMC IAvailability"
{
    Access = Public;

    procedure AvailableToPromise(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; RequestedDate: Date): Decimal
    procedure BandFor(ItemNo: Code[20]; LocationCode: Code[10]): Enum "CMC Stock Band"
}
