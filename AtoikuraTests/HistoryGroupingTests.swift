import XCTest
@testable import Atoikura

final class HistoryGroupingTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testItemsAreGroupedByMonthAndSortedNewestFirst() {
        let january = IncomeTransaction(amount: 100_000, date: date(year: 2026, month: 1, day: 10))
        let marchEarly = ExpenseTransaction(amount: 5_000, date: date(year: 2026, month: 3, day: 1))
        let marchLate = IncomeTransaction(amount: 200_000, date: date(year: 2026, month: 3, day: 20))

        let items: [HistoryItem] = [
            .income(january),
            .expense(marchEarly),
            .income(marchLate)
        ]

        let sections = HistoryGrouping.monthlySections(items: items, calendar: calendar)

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].title, "2026年3月")
        XCTAssertEqual(sections[0].items.count, 2)
        // 同じ月の中では新しい日付が先に来る
        XCTAssertEqual(sections[0].items.first?.date, marchLate.date)
        XCTAssertEqual(sections[1].title, "2026年1月")
        XCTAssertEqual(sections[1].items.count, 1)
    }

    func testEmptyItemsProduceNoSections() {
        XCTAssertTrue(HistoryGrouping.monthlySections(items: [], calendar: calendar).isEmpty)
    }
}
