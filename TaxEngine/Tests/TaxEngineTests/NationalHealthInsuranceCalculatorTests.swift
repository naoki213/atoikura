import XCTest
@testable import TaxEngine

final class NationalHealthInsuranceCalculatorTests: XCTestCase {
    private let calculator = NationalHealthInsuranceCalculator()

    func testUnsetAmountIsTreatedAsZeroButFlaggedAsNotUserProvided() {
        let profile = TaxProfile(
            year: 2026,
            businessProfit: 5_000_000,
            filingType: .white,
            blueReturnDeduction: .notEligible,
            nationalHealthInsuranceAnnualAmount: 300_000,
            hasSetNationalHealthInsuranceAmount: false
        )
        let result = calculator.calculate(profile: profile)
        XCTAssertEqual(result.annualAmount, 0)
        XCTAssertFalse(result.isUserProvided)
    }

    func testUserProvidedAmountIsUsedAsIs() {
        let profile = TaxProfile(
            year: 2026,
            businessProfit: 5_000_000,
            filingType: .white,
            blueReturnDeduction: .notEligible,
            nationalHealthInsuranceAnnualAmount: 300_000,
            hasSetNationalHealthInsuranceAmount: true
        )
        let result = calculator.calculate(profile: profile)
        XCTAssertEqual(result.annualAmount, 300_000)
        XCTAssertTrue(result.isUserProvided)
    }
}
