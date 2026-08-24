namespace CommerceConnector.Pricing;

using CommerceConnector.General;

interface "CMC IPriceResolver"
{
    Access = Public;

    procedure ResolveLine(CustomerNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; Quantity: Decimal; RequestedDate: Date; var UnitPrice: Decimal; var PriceSource: Enum "CMC Price Source"): Boolean
    procedure ResolveBatch(CustomerNo: Code[20]; var PriceRequestLine: Record "CMC Price Request Line" temporary): Integer
}
