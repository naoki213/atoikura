import XCTest
@testable import TaxEngine

final class TaxEngineFacadeTests: XCTestCase {
    func testCalculateAggregatesAllComponents() {
        let profile = TaxProfile(
            year: 2026,
            businessProfit: 5_390_000,
            filingType: .blue,
            blueReturnDeduction: .doubleEntryElectronicFiling,
            dependentsCount: 0,
            hasSpouse: false,
            isNationalPensionEnrolled: true,
            nationalHealthInsuranceAnnualAmount: 300_000,
            hasSetNationalHealthInsuranceAmount: true,
            businessTaxCategory: .rate5Percent
        )

        let result = TaxEngine.calculate(profile: profile)

        XCTAssertEqual(result.ruleSetYear, 2026)
        XCTAssertGreaterThan(result.incomeTax.totalAmount, 0)
        XCTAssertGreaterThan(result.residentTax.totalAmount, 0)
        XCTAssertEqual(result.nationalPension.annualAmount, 17_920 * 12)
        XCTAssertEqual(result.nationalHealthInsurance.annualAmount, 300_000)
        XCTAssertEqual(
            result.totalAmount,
            result.incomeTax.totalAmount
                + result.residentTax.totalAmount
                + result.nationalPension.annualAmount
                + result.nationalHealthInsurance.annualAmount
                + result.businessTax.totalAmount
        )
    }

    func testUnknownYearFallsBackToLatestKnownRuleSet() {
        let profile = TaxProfile(
            year: 2030,
            businessProfit: 3_000_000,
            filingType: .white,
            blueReturnDeduction: .notEligible
        )
        let result = TaxEngine.calculate(profile: profile)
        XCTAssertEqual(result.ruleSetYear, 2026)
    }
}
