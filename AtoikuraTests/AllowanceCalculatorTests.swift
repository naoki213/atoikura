import XCTest
import TaxEngine
@testable import Atoikura

final class AllowanceCalculatorTests: XCTestCase {
    func testRemainingAllowanceFormula() {
        let forecast = AnnualForecast(
            year: 2026,
            revenueForecast: 6_820_000,
            expenseForecast: 1_430_000,
            isRevenueManual: false,
            isExpenseManual: false
        )
        let userProfile = UserProfile(filingType: .blue)
        let taxSettings = TaxSettings(
            year: 2026,
            blueReturnDeduction: .doubleEntryElectronicFiling,
            isNationalPensionEnrolled: true,
            nationalHealthInsuranceAnnualAmount: 300_000,
            hasSetNationalHealthInsuranceAmount: true
        )
        let reserveSettings = ReserveSettings(businessReserveAmount: 600_000, otherReserveAmount: 0)

        let breakdown = AllowanceCalculator.calculate(
            forecast: forecast,
            userProfile: userProfile,
            taxSettings: taxSettings,
            reserveSettings: reserveSettings
        )

        XCTAssertEqual(breakdown.projectedProfit, 5_390_000)
        XCTAssertEqual(breakdown.taxAndSocialInsuranceReserve, breakdown.taxCalculationResult.totalAmount)
        XCTAssertEqual(breakdown.businessReserve, 600_000)
        XCTAssertEqual(
            breakdown.remainingAllowance,
            breakdown.projectedProfit - breakdown.taxAndSocialInsuranceReserve - 600_000
        )
    }

    func testNegativeProfitClampsBusinessProfitButKeepsRealAllowanceNegative() {
        let forecast = AnnualForecast(
            year: 2026,
            revenueForecast: 1_000_000,
            expenseForecast: 2_000_000,
            isRevenueManual: false,
            isExpenseManual: false
        )
        let userProfile = UserProfile(filingType: .white)
        let taxSettings = TaxSettings(year: 2026)
        let reserveSettings = ReserveSettings(businessReserveAmount: 0, otherReserveAmount: 0)

        let breakdown = AllowanceCalculator.calculate(
            forecast: forecast,
            userProfile: userProfile,
            taxSettings: taxSettings,
            reserveSettings: reserveSettings
        )

        XCTAssertEqual(breakdown.projectedProfit, -1_000_000)
        XCTAssertEqual(breakdown.taxCalculationResult.incomeTax.totalIncome, 0)
        // 赤字であることが「あと使えるお金」にそのまま反映される（税計算のクランプに引きずられない）
        XCTAssertLessThan(breakdown.remainingAllowance, 0)
    }
}
