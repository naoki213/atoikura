import Foundation

/// 1年分の税金・社会保険の計算結果一式。
///
/// 税額そのものだけでなく、課税所得・適用控除・適用税率・計算年度などの内訳も保持し、
/// 後からユーザーへ計算根拠を表示できるようにしている。
public struct TaxCalculationResult: Equatable, Sendable {
    public let year: Int

    /// 実際に計算へ使用したルールセットの年度（要求年度に対応するルールが無い場合は
    /// `TaxRuleSetRegistry` が直近の年度にフォールバックするため、`year` と異なることがある）。
    public let ruleSetYear: Int

    public let incomeTax: IncomeTaxResult
    public let residentTax: ResidentTaxResult
    public let nationalPension: NationalPensionResult
    public let nationalHealthInsurance: NationalHealthInsuranceResult
    public let businessTax: BusinessTaxResult

    /// 税金・社会保険の合計額（概算）。ホーム画面の「税金・社会保険として確保」に対応する。
    public var totalAmount: Decimal {
        incomeTax.totalAmount
            + residentTax.totalAmount
            + nationalPension.annualAmount
            + nationalHealthInsurance.annualAmount
            + businessTax.totalAmount
    }
}
