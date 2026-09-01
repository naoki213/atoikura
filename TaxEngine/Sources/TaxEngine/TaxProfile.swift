import Foundation

/// 1年分の税計算に必要な入力情報。
///
/// Ver1.0では事業所得のみを対象とし、給与所得など他の所得区分は考慮しない
/// （個人事業主・フリーランス向けアプリという前提の単純化）。
public struct TaxProfile: Equatable, Sendable {
    public var year: Int

    /// 売上から経費（事業割合適用後）を差し引いた事業所得（青色申告特別控除前）。
    public var businessProfit: Decimal

    public var filingType: FilingType
    public var blueReturnDeduction: BlueReturnDeductionType

    public var dependentsCount: Int
    public var hasSpouse: Bool

    public var isNationalPensionEnrolled: Bool

    /// 国民健康保険の年額（自治体差が大きいためユーザーが入力した金額をそのまま使う）。
    public var nationalHealthInsuranceAnnualAmount: Decimal

    /// `nationalHealthInsuranceAnnualAmount` がユーザーによって入力済みかどうか。
    /// falseの場合、金額は0として扱われるが「未設定」であることを結果に残す。
    public var hasSetNationalHealthInsuranceAmount: Bool

    public var businessTaxCategory: BusinessTaxCategory

    public init(
        year: Int,
        businessProfit: Decimal,
        filingType: FilingType,
        blueReturnDeduction: BlueReturnDeductionType,
        dependentsCount: Int = 0,
        hasSpouse: Bool = false,
        isNationalPensionEnrolled: Bool = true,
        nationalHealthInsuranceAnnualAmount: Decimal = 0,
        hasSetNationalHealthInsuranceAmount: Bool = false,
        businessTaxCategory: BusinessTaxCategory = .rate5Percent
    ) {
        self.year = year
        self.businessProfit = businessProfit
        self.filingType = filingType
        self.blueReturnDeduction = blueReturnDeduction
        self.dependentsCount = dependentsCount
        self.hasSpouse = hasSpouse
        self.isNationalPensionEnrolled = isNationalPensionEnrolled
        self.nationalHealthInsuranceAnnualAmount = nationalHealthInsuranceAnnualAmount
        self.hasSetNationalHealthInsuranceAmount = hasSetNationalHealthInsuranceAmount
        self.businessTaxCategory = businessTaxCategory
    }
}
