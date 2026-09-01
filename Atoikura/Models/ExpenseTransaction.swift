import Foundation
import SwiftData

/// 経費の1件の取引記録。
@Model
final class ExpenseTransaction {
    var amount: Decimal
    var date: Date
    var category: ExpenseCategory
    var memo: String

    /// 事業割合（%）。100なら全額経費、50なら半分だけ経費として扱う。
    var businessRatioPercent: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        amount: Decimal,
        date: Date = .now,
        category: ExpenseCategory = .other,
        memo: String = "",
        businessRatioPercent: Int = 100,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.amount = amount
        self.date = date
        self.category = category
        self.memo = memo
        self.businessRatioPercent = businessRatioPercent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 税計算・集計に使う実際の経費額（金額 × 事業割合）。
    var deductibleAmount: Decimal {
        amount * Decimal(businessRatioPercent) / 100
    }
}
