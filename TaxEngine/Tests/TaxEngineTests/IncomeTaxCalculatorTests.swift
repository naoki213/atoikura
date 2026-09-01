import XCTest
@testable import TaxEngine

final class IncomeTaxCalculatorTests: XCTestCase {
    private let calculator = IncomeTaxCalculator(ruleSet: TaxRules2026())

    private func makeProfile(businessProfit: Decimal) -> TaxProfile {
        TaxProfile(
            year: 2026,
            businessProfit: businessProfit,
            filingType: .white,
            blueReturnDeduction: .notEligible,
            dependentsCount: 0,
            hasSpouse: false,
            isNationalPensionEnrolled: false,
            nationalHealthInsuranceAnnualAmount: 0,
            hasSetNationalHealthInsuranceAmount: false
        )
    }

    // MARK: - 課税所得の境界値

    func testApplicableBracketAtZeroTaxableIncome() {
        let bracket = calculator.applicableBracket(for: 0)
        XCTAssertEqual(bracket.rate, 0.05)
    }

    func testApplicableBracketAtOneYenTaxableIncome() {
        let bracket = calculator.applicableBracket(for: 1)
        XCTAssertEqual(bracket.rate, 0.05)
    }

    func testApplicableBracketJustBelowFirstBoundary() {
        let bracket = calculator.applicableBracket(for: 1_949_000)
        XCTAssertEqual(bracket.rate, 0.05)
    }

    func testApplicableBracketExactlyAtFirstBoundaryIsInclusive() {
        let bracket = calculator.applicableBracket(for: 1_950_000)
        XCTAssertEqual(bracket.rate, 0.05)
    }

    func testApplicableBracketJustAboveFirstBoundary() {
        let bracket = calculator.applicableBracket(for: 1_951_000)
        XCTAssertEqual(bracket.rate, 0.10)
    }

    func testApplicableBracketAtHighestBoundaryHasNoUpperBound() {
        let bracket = calculator.applicableBracket(for: 100_000_000)
        XCTAssertEqual(bracket.rate, 0.45)
        XCTAssertNil(bracket.upperBound)
    }

    // MARK: - 事業所得ゼロ・赤字

    func testZeroProfitResultsInZeroTax() {
        let result = calculator.calculate(profile: makeProfile(businessProfit: 0), nationalPensionAnnualAmount: 0)
        XCTAssertEqual(result.taxableIncome, 0)
        XCTAssertEqual(result.totalAmount, 0)
    }

    // MARK: - 実際の計算フロー（境界を跨ぐ課税所得を作る）

    func testTaxableIncomeExactlyAtBracketBoundaryUsesLowerRate() {
        // totalIncome=2,830,000 -> 基礎控除880,000 -> 課税所得1,950,000（境界ちょうど）
        let profile = makeProfile(businessProfit: 2_830_000)
        let result = calculator.calculate(profile: profile, nationalPensionAnnualAmount: 0)

        XCTAssertEqual(result.taxableIncome, 1_950_000)
        XCTAssertEqual(result.appliedBracket.rate, 0.05)
        XCTAssertEqual(result.incomeTaxBeforeSurtax, 97_500)
    }

    func testTaxableIncomeJustAboveBracketBoundaryUsesHigherRate() {
        // totalIncome=2,831,000 -> 基礎控除880,000 -> 課税所得1,951,000（境界+1,000円）
        let profile = makeProfile(businessProfit: 2_831_000)
        let result = calculator.calculate(profile: profile, nationalPensionAnnualAmount: 0)

        XCTAssertEqual(result.taxableIncome, 1_951_000)
        XCTAssertEqual(result.appliedBracket.rate, 0.10)
        XCTAssertEqual(result.incomeTaxBeforeSurtax, 97_600)
    }

    // MARK: - 青色申告特別控除

    func testBlueReturnDeductionReducesTotalIncome() {
        var profile = makeProfile(businessProfit: 5_000_000)
        profile.filingType = .blue
        profile.blueReturnDeduction = .doubleEntryElectronicFiling

        let result = calculator.calculate(profile: profile, nationalPensionAnnualAmount: 0)

        XCTAssertEqual(result.blueReturnDeduction, 650_000)
        XCTAssertEqual(result.totalIncome, 5_000_000 - 650_000)
    }

    func testBlueReturnDeductionNeverMakesTotalIncomeNegative() {
        var profile = makeProfile(businessProfit: 100_000)
        profile.filingType = .blue
        profile.blueReturnDeduction = .doubleEntryElectronicFiling

        let result = calculator.calculate(profile: profile, nationalPensionAnnualAmount: 0)

        XCTAssertEqual(result.totalIncome, 0)
        XCTAssertEqual(result.totalAmount, 0)
    }

    // MARK: - 社会保険料控除（国民年金・国民健康保険）

    func testSocialInsuranceDeductionReducesTaxableIncome() {
        let profile = makeProfile(businessProfit: 5_000_000)
        let withoutInsurance = calculator.calculate(profile: profile, nationalPensionAnnualAmount: 0)
        let withInsurance = calculator.calculate(profile: profile, nationalPensionAnnualAmount: 214_800)

        XCTAssertLessThan(withInsurance.taxableIncome, withoutInsurance.taxableIncome)
    }
}
