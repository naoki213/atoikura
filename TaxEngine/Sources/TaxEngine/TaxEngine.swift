import Foundation

/// TaxEngineの公開窓口。`TaxProfile` を渡すと、年度に対応するルールセットを選び、
/// 各Calculatorを正しい順序（国民年金 → 所得税/住民税/個人事業税/国民健康保険）で実行して
/// `TaxCalculationResult` にまとめる。
///
/// このファイルを含め、`TaxEngine` パッケージ全体はSwiftUI/SwiftData/UIKitに依存しない。
/// アプリ側は `Atoikura/Services` から `TaxProfile` を組み立ててこのAPIを呼び出す。
public enum TaxEngine {
    public static func calculate(profile: TaxProfile) -> TaxCalculationResult {
        let ruleSet = TaxRuleSetRegistry.ruleSet(for: profile.year)

        let pensionResult = NationalPensionCalculator(ruleSet: ruleSet).calculate(profile: profile)
        let healthInsuranceResult = NationalHealthInsuranceCalculator().calculate(profile: profile)

        let incomeTaxResult = IncomeTaxCalculator(ruleSet: ruleSet).calculate(
            profile: profile,
            nationalPensionAnnualAmount: pensionResult.annualAmount
        )
        let residentTaxResult = ResidentTaxCalculator(ruleSet: ruleSet).calculate(
            profile: profile,
            nationalPensionAnnualAmount: pensionResult.annualAmount
        )
        let businessTaxResult = BusinessTaxCalculator(ruleSet: ruleSet).calculate(profile: profile)

        return TaxCalculationResult(
            year: profile.year,
            ruleSetYear: ruleSet.year,
            incomeTax: incomeTaxResult,
            residentTax: residentTaxResult,
            nationalPension: pensionResult,
            nationalHealthInsurance: healthInsuranceResult,
            businessTax: businessTaxResult
        )
    }
}
