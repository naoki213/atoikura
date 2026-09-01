import Foundation

/// 特定年度の売上・経費の実績集計。
struct AnnualActuals: Equatable {
    let year: Int
    let totalRevenue: Decimal
    /// 経費は「金額 × 事業割合」を適用した後の合計。
    let totalExpense: Decimal
    /// 実績ベースの単純年間換算に使う経過月数（1〜12）。今年より前の年度なら12、
    /// まだ来ていない年度なら0として扱う。
    let elapsedMonths: Int
}

/// SwiftDataから取得した取引一覧を、年度ごとの実績（売上・経費の合計）に集計する。
enum AnnualSummaryService {
    static func actuals(
        year: Int,
        incomeTransactions: [IncomeTransaction],
        expenseTransactions: [ExpenseTransaction],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) -> AnnualActuals {
        let yearIncomes = incomeTransactions.filter { calendar.component(.year, from: $0.date) == year }
        let yearExpenses = expenseTransactions.filter { calendar.component(.year, from: $0.date) == year }

        let totalRevenue = yearIncomes.reduce(Decimal(0)) { $0 + $1.amount }
        let totalExpense = yearExpenses.reduce(Decimal(0)) { $0 + $1.deductibleAmount }

        let currentYear = calendar.component(.year, from: referenceDate)
        let elapsedMonths: Int
        if year < currentYear {
            elapsedMonths = 12
        } else if year > currentYear {
            elapsedMonths = 0
        } else {
            elapsedMonths = calendar.component(.month, from: referenceDate)
        }

        return AnnualActuals(
            year: year,
            totalRevenue: totalRevenue,
            totalExpense: totalExpense,
            elapsedMonths: elapsedMonths
        )
    }
}
