import XCTest
@testable import TaxEngine

final class BusinessTaxCalculatorTests: XCTestCase {
    private let calculator = BusinessTaxCalculator(ruleSet: TaxRules2026())

    private func makeProfile(businessProfit: Decimal, category: BusinessTaxCategory = .rate5Percent) -> TaxProfile {
        TaxProfile(
            year: 2026,
            businessProfit: businessProfit,
            filingType: .white,
            blueReturnDeduction: .notEligible,
            businessTaxCategory: category
        )
    }

    func testProfitBelowDeductionResultsInZeroTax() {
        let result = calculator.calculate(profile: makeProfile(businessProfit: 2_000_000))
        XCTAssertEqual(result.taxableAmount, 0)
        XCTAssertEqual(result.totalAmount, 0)
    }

    func testProfitExactlyAtDeductionBoundaryResultsInZeroTax() {
        let result = calculator.calculate(profile: makeProfile(businessProfit: 2_900_000))
        XCTAssertEqual(result.taxableAmount, 0)
        XCTAssertEqual(result.totalAmount, 0)
    }

    func testProfitAboveDeductionIsTaxed() {
        let result = calculator.calculate(profile: makeProfile(businessProfit: 3_000_000))
        XCTAssertEqual(result.taxableAmount, 100_000)
        XCTAssertEqual(result.totalAmount, 5_000)
    }

    func testExemptCategoryIsNeverTaxed() {
        let result = calculator.calculate(profile: makeProfile(businessProfit: 10_000_000, category: .exempt))
        XCTAssertEqual(result.totalAmount, 0)
    }

    /// 個人事業税は青色申告特別控除を差し引く前の事業所得に課税される。
    func testBusinessTaxIgnoresBlueReturnDeduction() {
        var profile = makeProfile(businessProfit: 3_000_000)
        profile.filingType = .blue
        profile.blueReturnDeduction = .doubleEntryElectronicFiling

        let result = calculator.calculate(profile: profile)

        XCTAssertEqual(result.taxableAmount, 100_000)
        XCTAssertEqual(result.totalAmount, 5_000)
    }
}
