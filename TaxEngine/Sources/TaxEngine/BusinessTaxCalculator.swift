import Foundation

public struct BusinessTaxResult: Equatable, Sendable {
    /// 課税標準額（事業所得(青色申告特別控除前) − 事業主控除）。
    public let taxableAmount: Decimal
    public let rate: Decimal
    public let deduction: Decimal
    public let totalAmount: Decimal
}

/// 個人事業税の概算計算。
///
/// 個人事業税は青色申告特別控除を差し引く前の事業所得に対して課税される点に注意
/// （所得税・住民税とは課税標準の考え方が異なる）。
public struct BusinessTaxCalculator {
    private let ruleSet: TaxRuleSet

    public init(ruleSet: TaxRuleSet) {
        self.ruleSet = ruleSet
    }

    public func calculate(profile: TaxProfile) -> BusinessTaxResult {
        let deduction = ruleSet.businessTaxDeduction
        let taxableAmount = max(0, profile.businessProfit - deduction)
        let rate = ruleSet.businessTaxRate(for: profile.businessTaxCategory)
        let totalAmount = TaxRounding.taxAmount(taxableAmount * rate)

        return BusinessTaxResult(
            taxableAmount: taxableAmount,
            rate: rate,
            deduction: deduction,
            totalAmount: totalAmount
        )
    }
}
