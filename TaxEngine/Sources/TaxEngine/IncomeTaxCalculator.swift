import Foundation

public struct IncomeTaxResult: Equatable, Sendable {
    public let year: Int

    /// 合計所得金額（事業所得、青色申告特別控除後）。Ver1.0では他の所得区分は考慮しない。
    public let totalIncome: Decimal

    public let blueReturnDeduction: Decimal
    public let basicDeduction: Decimal
    public let spouseDeduction: Decimal
    public let dependentDeduction: Decimal
    public let socialInsuranceDeduction: Decimal

    /// 課税所得（1,000円未満切り捨て後）。
    public let taxableIncome: Decimal
    public let appliedBracket: IncomeTaxBracket

    public let incomeTaxBeforeSurtax: Decimal
    public let reconstructionSurtax: Decimal

    /// 所得税及び復興特別所得税の合計額（概算、100円未満切り捨て）。
    public let totalAmount: Decimal
}

/// 所得税（及び復興特別所得税）の概算計算。
public struct IncomeTaxCalculator {
    private let ruleSet: TaxRuleSet

    public init(ruleSet: TaxRuleSet) {
        self.ruleSet = ruleSet
    }

    public func calculate(profile: TaxProfile, nationalPensionAnnualAmount: Decimal) -> IncomeTaxResult {
        let blueDeduction = ruleSet.blueReturnDeductionAmount(for: profile.blueReturnDeduction)
        let totalIncome = max(0, profile.businessProfit - blueDeduction)

        let basicDeduction = ruleSet.incomeTaxBasicDeduction(totalIncome: totalIncome)
        let spouseDeduction = profile.hasSpouse ? ruleSet.incomeTaxSpouseDeduction : 0
        let dependentDeduction = Decimal(profile.dependentsCount) * ruleSet.incomeTaxDependentDeduction
        let socialInsuranceDeduction = nationalPensionAnnualAmount
            + (profile.hasSetNationalHealthInsuranceAmount ? profile.nationalHealthInsuranceAnnualAmount : 0)

        let totalDeductions = basicDeduction + spouseDeduction + dependentDeduction + socialInsuranceDeduction
        let taxableIncome = TaxRounding.taxableIncome(max(0, totalIncome - totalDeductions))

        let bracket = applicableBracket(for: taxableIncome)
        let incomeTaxBeforeSurtax = max(0, taxableIncome * bracket.rate - bracket.baseDeduction)
        let reconstructionSurtax = incomeTaxBeforeSurtax * ruleSet.reconstructionSurtaxRate
        let totalAmount = TaxRounding.taxAmount(incomeTaxBeforeSurtax + reconstructionSurtax)

        return IncomeTaxResult(
            year: profile.year,
            totalIncome: totalIncome,
            blueReturnDeduction: blueDeduction,
            basicDeduction: basicDeduction,
            spouseDeduction: spouseDeduction,
            dependentDeduction: dependentDeduction,
            socialInsuranceDeduction: socialInsuranceDeduction,
            taxableIncome: taxableIncome,
            appliedBracket: bracket,
            incomeTaxBeforeSurtax: incomeTaxBeforeSurtax,
            reconstructionSurtax: reconstructionSurtax,
            totalAmount: totalAmount
        )
    }

    /// `internal`（非public）だが、境界値のユニットテストのために `@testable import` から直接呼べるようにしている。
    func applicableBracket(for taxableIncome: Decimal) -> IncomeTaxBracket {
        for bracket in ruleSet.incomeTaxBrackets {
            if let upperBound = bracket.upperBound {
                if taxableIncome <= upperBound {
                    return bracket
                }
            } else {
                return bracket
            }
        }
        // incomeTaxBrackets は必ず upperBound == nil の区分（最高税率）を含む前提。
        return ruleSet.incomeTaxBrackets[ruleSet.incomeTaxBrackets.count - 1]
    }
}
