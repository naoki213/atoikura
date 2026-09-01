import XCTest
@testable import Atoikura

/// アプリ側のユニットテスト（SwiftDataモデル・集計/予測サービスなど）。
/// 税計算そのもののテストは `TaxEngine/Tests/TaxEngineTests` に置く。
final class AtoikuraTests: XCTestCase {
    func testExpenseTransactionDeductibleAmountAppliesBusinessRatio() {
        let expense = ExpenseTransaction(amount: 10_000, businessRatioPercent: 50)
        XCTAssertEqual(expense.deductibleAmount, 5_000)
    }

    func testExpenseTransactionDefaultBusinessRatioIsFullyDeductible() {
        let expense = ExpenseTransaction(amount: 10_000)
        XCTAssertEqual(expense.deductibleAmount, 10_000)
    }
}
