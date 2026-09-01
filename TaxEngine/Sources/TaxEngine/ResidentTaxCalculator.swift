import Foundation

public struct ResidentTaxResult: Equatable, Sendable {
    public let year: Int
    public let totalIncome: Decimal
    public let basicDeduction: Decimal
    public let spouseDeduction: Decimal
    public let dependentDeduction: Decimal
    public let socialInsuranceDeduction: Decimal
    public let taxableIncome: Decimal

    /// 所得割額。
    public let incomeLevy: Decimal
    /// 均等割額。
    public let perCapitaLevy: Decimal
    public let totalAmount: Decimal
}

/// 住民税の概算計算。
///
/// 実際の住民税は「前年の所得」に対して翌年度課税されるが、Ver1.0では
/// 「今の所得水準ならこれくらいの住民税がかかる」という直感的な概算を優先し、
/// 同一年内の所得から住民税相当額を計算して表示する（時期のズレは考慮しない簡略化）。
public struct ResidentTaxCalculator {
    private let ruleSet: TaxRuleSet

    public init(ruleSet: TaxRuleSet) {
        self.ruleSet = ruleSet
    }

    public func calculate(profile: TaxProfile, nationalPensionAnnualAmount: Decimal) -> ResidentTaxResult {
        let blueDeduction = ruleSet.blueReturnDeductionAmount(for: profile.blueReturnDeduction)
        let totalIncome = max(0, profile.businessProfit - blueDeduction)

        let basicDeduction = ruleSet.residentTaxBasicDeduction(totalIncome: totalIncome)
        let spouseDeduction = profile.hasSpouse ? ruleSet.residentTaxSpouseDeduction : 0
        let dependentDeduction = Decimal(profile.dependentsCount) * ruleSet.residentTaxDependentDeduction
        let socialInsuranceDeduction = nationalPensionAnnualAmount
            + (profile.hasSetNationalHealthInsuranceAmount ? profile.nationalHealthInsuranceAnnualAmount : 0)

        let totalDeductions = basicDeduction + spouseDeduction + dependentDeduction + socialInsuranceDeduction
        let taxableIncome = TaxRounding.taxableIncome(max(0, totalIncome - totalDeductions))

        let incomeLevy = TaxRounding.taxAmount(taxableIncome * ruleSet.residentTaxIncomeRate)
        let perCapitaLevy = taxableIncome > 0 ? ruleSet.residentTaxPerCapita : 0

        return ResidentTaxResult(
            year: profile.year,
            totalIncome: totalIncome,
            basicDeduction: basicDeduction,
            spouseDeduction: spouseDeduction,
            dependentDeduction: dependentDeduction,
            socialInsuranceDeduction: socialInsuranceDeduction,
            taxableIncome: taxableIncome,
            incomeLevy: incomeLevy,
            perCapitaLevy: perCapitaLevy,
            totalAmount: incomeLevy + perCapitaLevy
        )
    }
}
