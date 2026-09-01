import XCTest
@testable import TaxEngine

final class TaxRoundingTests: XCTestCase {
    func testTaxableIncomeFlooringBoundaries() {
        XCTAssertEqual(TaxRounding.taxableIncome(0), 0)
        XCTAssertEqual(TaxRounding.taxableIncome(1), 0)
        XCTAssertEqual(TaxRounding.taxableIncome(999), 0)
        XCTAssertEqual(TaxRounding.taxableIncome(1_000), 1_000)
        XCTAssertEqual(TaxRounding.taxableIncome(1_001), 1_000)
        XCTAssertEqual(TaxRounding.taxableIncome(1_999), 1_000)
        XCTAssertEqual(TaxRounding.taxableIncome(2_000), 2_000)
    }

    func testTaxAmountFlooringBoundaries() {
        XCTAssertEqual(TaxRounding.taxAmount(0), 0)
        XCTAssertEqual(TaxRounding.taxAmount(1), 0)
        XCTAssertEqual(TaxRounding.taxAmount(99), 0)
        XCTAssertEqual(TaxRounding.taxAmount(100), 100)
        XCTAssertEqual(TaxRounding.taxAmount(199), 100)
        XCTAssertEqual(TaxRounding.taxAmount(200), 200)
    }

    func testNegativeValuesFloorToZero() {
        XCTAssertEqual(TaxRounding.taxableIncome(-1), 0)
        XCTAssertEqual(TaxRounding.taxAmount(-100), 0)
    }
}
