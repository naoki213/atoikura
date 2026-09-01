import XCTest
@testable import Atoikura

final class AnnualForecastServiceTests: XCTestCase {
    func testAutoForecastProjectsFromElapsedMonths() {
        let actuals = AnnualActuals(year: 2026, totalRevenue: 3_000_000, totalExpense: 600_000, elapsedMonths: 6)
        let forecast = AnnualForecastService.forecast(
            actuals: actuals,
            manualRevenueForecast: nil,
            manualExpenseForecast: nil
        )

        XCTAssertEqual(forecast.revenueForecast, 6_000_000)
        XCTAssertEqual(forecast.expenseForecast, 1_200_000)
        XCTAssertFalse(forecast.isRevenueManual)
        XCTAssertFalse(forecast.isExpenseManual)
    }

    func testManualForecastOverridesAutoForecast() {
        let actuals = AnnualActuals(year: 2026, totalRevenue: 3_000_000, totalExpense: 600_000, elapsedMonths: 6)
        let forecast = AnnualForecastService.forecast(
            actuals: actuals,
            manualRevenueForecast: 8_000_000,
            manualExpenseForecast: nil
        )

        XCTAssertEqual(forecast.revenueForecast, 8_000_000)
        XCTAssertTrue(forecast.isRevenueManual)
        XCTAssertEqual(forecast.expenseForecast, 1_200_000)
        XCTAssertFalse(forecast.isExpenseManual)
    }

    func testZeroElapsedMonthsFallsBackToRawActualWithoutDivideByZero() {
        let actuals = AnnualActuals(year: 2027, totalRevenue: 0, totalExpense: 0, elapsedMonths: 0)
        let forecast = AnnualForecastService.forecast(
            actuals: actuals,
            manualRevenueForecast: nil,
            manualExpenseForecast: nil
        )
        XCTAssertEqual(forecast.revenueForecast, 0)
        XCTAssertEqual(forecast.expenseForecast, 0)
    }
}
