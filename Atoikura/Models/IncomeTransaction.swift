import Foundation
import SwiftData

/// 売上（収入）の1件の取引記録。
@Model
final class IncomeTransaction {
    var amount: Decimal
    var date: Date
    var clientName: String
    var memo: String
    var isPaid: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        amount: Decimal,
        date: Date = .now,
        clientName: String = "",
        memo: String = "",
        isPaid: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.amount = amount
        self.date = date
        self.clientName = clientName
        self.memo = memo
        self.isPaid = isPaid
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
