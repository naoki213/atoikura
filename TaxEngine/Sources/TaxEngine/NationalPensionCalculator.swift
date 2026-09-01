import Foundation

public struct NationalPensionResult: Equatable, Sendable {
    public let isEnrolled: Bool
    public let monthlyAmount: Decimal
    public let annualAmount: Decimal
}

/// 国民年金保険料の概算計算。月額 × 12 の単純計算（月ごとの増減は考慮しない）。
public struct NationalPensionCalculator {
    private let ruleSet: TaxRuleSet

    public init(ruleSet: TaxRuleSet) {
        self.ruleSet = ruleSet
    }

    public func calculate(profile: TaxProfile) -> NationalPensionResult {
        guard profile.isNationalPensionEnrolled else {
            return NationalPensionResult(isEnrolled: false, monthlyAmount: 0, annualAmount: 0)
        }
        let monthly = ruleSet.nationalPensionMonthlyAmount
        return NationalPensionResult(isEnrolled: true, monthlyAmount: monthly, annualAmount: monthly * 12)
    }
}
