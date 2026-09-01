import XCTest
@testable import TaxEngine

final class ResidentTaxCalculatorTests: XCTestCase {
    private let calculator = ResidentTaxCalculator(ruleSet: TaxRules2026())

    private func makeProfile(businessProfit: Decimal) -> TaxProfile {
        TaxProfile(
            year: 2026,
            businessProfit: businessProfit,
            filingType: .white,
            blueReturnDeduction: .notEligible
        )
    }

    func testZeroProfitResultsInZeroResidentTax() {
        let result = calculator.calculate(profile: makeProfile(businessProfit: 0), nationalPensionAnnualAmount: 0)
        XCTAssertEqual(result.taxableIncome, 0)
        XCTAssertEqual(result.perCapitaLevy, 0)
        XCTAssertEqual(result.totalAmount, 0)
    }

    func testPerCapitaLevyIsChargedWhenTaxableIncomeIsPositive() {
        let result = calculator.calculate(profile: makeProfile(businessProfit: 5_000_000), nationalPensionAnnualAmount: 0)
        XCTAssertGreaterThan(result.taxableIncome, 0)
        XCTAssertEqual(result.perCapitaLevy, 5_000)
    }

    func testIncomeLevyIsTenPercentOfTaxableIncome() {
        // totalIncome=1,000,000, 基礎控除(住民税)=900,000 -> 課税所得100,000
        let result = calculator.calculate(profile: makeProfile(businessProfit: 1_000_000), nationalPensionAnnualAmount: 0)
        XCTAssertEqual(result.taxableIncome, 100_000)
        XCTAssertEqual(result.incomeLevy, 10_000)
    }
}
