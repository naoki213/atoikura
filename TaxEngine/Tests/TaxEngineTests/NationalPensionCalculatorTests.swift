import XCTest
@testable import TaxEngine

final class NationalPensionCalculatorTests: XCTestCase {
    private let calculator = NationalPensionCalculator(ruleSet: TaxRules2026())

    private func makeProfile(isEnrolled: Bool) -> TaxProfile {
        TaxProfile(
            year: 2026,
            businessProfit: 5_000_000,
            filingType: .white,
            blueReturnDeduction: .notEligible,
            isNationalPensionEnrolled: isEnrolled
        )
    }

    func testEnrolledUsesMonthlyAmountTimesTwelve() {
        let result = calculator.calculate(profile: makeProfile(isEnrolled: true))
        XCTAssertEqual(result.monthlyAmount, 17_920)
        XCTAssertEqual(result.annualAmount, 17_920 * 12)
    }

    func testNotEnrolledResultsInZero() {
        let result = calculator.calculate(profile: makeProfile(isEnrolled: false))
        XCTAssertEqual(result.annualAmount, 0)
    }
}
