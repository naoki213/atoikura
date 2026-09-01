import XCTest
import SwiftData
@testable import Atoikura

/// SwiftDataへの保存・再取得・削除が正しく機能することを確認する（完成条件の
/// 「再起動してもデータが残っている」「編集・削除できる」を裏付けるテスト）。
final class PersistenceRoundTripTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            UserProfile.self,
            IncomeTransaction.self,
            ExpenseTransaction.self,
            TaxSettings.self,
            ReserveSettings.self,
            AppSettings.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    func testIncomeAndExpenseTransactionsSurviveSaveAndRefetch() throws {
        let context = try makeContext()

        context.insert(IncomeTransaction(amount: 1_000_000, clientName: "A社"))
        context.insert(ExpenseTransaction(amount: 300_000, category: .outsourcing))
        try context.save()

        let incomes = try context.fetch(FetchDescriptor<IncomeTransaction>())
        let expenses = try context.fetch(FetchDescriptor<ExpenseTransaction>())

        XCTAssertEqual(incomes.count, 1)
        XCTAssertEqual(incomes.first?.amount, 1_000_000)
        XCTAssertEqual(expenses.count, 1)
        XCTAssertEqual(expenses.first?.amount, 300_000)
    }

    func testEditingATransactionPersistsTheChange() throws {
        let context = try makeContext()
        let income = IncomeTransaction(amount: 500_000)
        context.insert(income)
        try context.save()

        income.amount = 750_000
        try context.save()

        let refetched = try context.fetch(FetchDescriptor<IncomeTransaction>()).first
        XCTAssertEqual(refetched?.amount, 750_000)
    }

    func testDeletingATransactionRemovesItFromFutureFetches() throws {
        let context = try makeContext()
        let expense = ExpenseTransaction(amount: 10_000)
        context.insert(expense)
        try context.save()

        context.delete(expense)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<ExpenseTransaction>())
        XCTAssertTrue(remaining.isEmpty)
    }
}
