import Foundation
import SwiftData

/// 売上（収入）の1件の取引記録。
@Model
final class IncomeTransaction {
    var amount: Decimal
    var date: Date
    var clientName: String
    var memo: String

    /// 自由記述の分類タグ（例: 「業務委託」「物販」）。経費と違い定型のカテゴリー一覧は設けず、
    /// ユーザーが任意の言葉で入力できるようにしている（詳細は DEVELOPMENT.md 参照）。
    var category: String
    var isPaid: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        amount: Decimal,
        date: Date = .now,
        clientName: String = "",
        memo: String = "",
        category: String = "",
        isPaid: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.amount = amount
        self.date = date
        self.clientName = clientName
        self.memo = memo
        self.category = category
        self.isPaid = isPaid
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
