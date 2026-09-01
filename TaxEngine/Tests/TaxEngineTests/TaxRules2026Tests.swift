import XCTest
@testable import TaxEngine

final class TaxRules2026Tests: XCTestCase {
    private let rules = TaxRules2026()

    func testIncomeTaxBasicDeductionBoundaries() {
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 0), 950_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 1_320_000), 950_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 1_320_001), 880_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 3_360_000), 880_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 3_360_001), 680_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 4_890_000), 680_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 4_890_001), 670_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 6_550_000), 670_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 6_550_001), 620_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 23_500_000), 620_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 23_500_001), 480_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 25_000_000), 160_000)
        XCTAssertEqual(rules.incomeTaxBasicDeduction(totalIncome: 25_000_001), 0)
    }

    func testResidentTaxBasicDeductionIsFiftyThousandLessThanIncomeTax() {
        XCTAssertEqual(rules.residentTaxBasicDeduction(totalIncome: 0), 900_000)
        XCTAssertEqual(rules.residentTaxBasicDeduction(totalIncome: 25_000_001), 0)
    }

    func testBlueReturnDeductionAmounts() {
        XCTAssertEqual(rules.blueReturnDeductionAmount(for: .notEligible), 0)
        XCTAssertEqual(rules.blueReturnDeductionAmount(for: .simplifiedBookkeeping), 100_000)
        XCTAssertEqual(rules.blueReturnDeductionAmount(for: .doubleEntryPaperFiling), 550_000)
        XCTAssertEqual(rules.blueReturnDeductionAmount(for: .doubleEntryElectronicFiling), 650_000)
    }

    func testBusinessTaxRates() {
        XCTAssertEqual(rules.businessTaxRate(for: .exempt), 0)
        XCTAssertEqual(rules.businessTaxRate(for: .rate3Percent), 0.03)
        XCTAssertEqual(rules.businessTaxRate(for: .rate4Percent), 0.04)
        XCTAssertEqual(rules.businessTaxRate(for: .rate5Percent), 0.05)
    }
}
