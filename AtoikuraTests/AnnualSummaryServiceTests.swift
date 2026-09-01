import XCTest
@testable import Atoikura

final class AnnualSummaryServiceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testSumsOnlyTransactionsWithinTheTargetYear() {
        let incomes = [
            IncomeTransaction(amount: 1_000_000, date: date(year: 2026, month: 3, day: 1)),
            IncomeTransaction(amount: 2_000_000, date: date(year: 2025, month: 12, day: 31))
        ]
        let expenses = [
            ExpenseTransaction(amount: 100_000, date: date(year: 2026, month: 3, day: 1), businessRatioPercent: 50)
        ]

        let actuals = AnnualSummaryService.actuals(
            year: 2026,
            incomeTransactions: incomes,
            expenseTransactions: expenses,
            calendar: calendar,
            referenceDate: date(year: 2026, month: 6, day: 15)
        )

        XCTAssertEqual(actuals.totalRevenue, 1_000_000)
        // 事業割合50%が適用される
        XCTAssertEqual(actuals.totalExpense, 50_000)
        XCTAssertEqual(actuals.elapsedMonths, 6)
    }

    func testPastYearUsesTwelveElapsedMonths() {
        let actuals = AnnualSummaryService.actuals(
            year: 2025,
            incomeTransactions: [],
            expenseTransactions: [],
            calendar: calendar,
            referenceDate: date(year: 2026, month: 6, day: 15)
        )
        XCTAssertEqual(actuals.elapsedMonths, 12)
    }

    func testFutureYearUsesZeroElapsedMonths() {
        let actuals = AnnualSummaryService.actuals(
            year: 2027,
            incomeTransactions: [],
            expenseTransactions: [],
            calendar: calendar,
            referenceDate: date(year: 2026, month: 6, day: 15)
        )
        XCTAssertEqual(actuals.elapsedMonths, 0)
    }
}
