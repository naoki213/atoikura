import Foundation
import Observation
import SwiftData

/// 経費の新規追加・編集を扱う。
@Observable
final class ExpenseEntryViewModel {
    var amount: Decimal?
    var date: Date
    var category: ExpenseCategory
    var memo: String
    var businessRatioPercent: Int

    private let existingTransaction: ExpenseTransaction?

    var isEditing: Bool { existingTransaction != nil }

    var hasDetailInput: Bool {
        !memo.isEmpty || businessRatioPercent != 100
    }

    var isSaveDisabled: Bool {
        guard let amount else { return true }
        return amount <= 0
    }

    init(transaction: ExpenseTransaction? = nil) {
        self.existingTransaction = transaction
        self.amount = transaction?.amount
        self.date = transaction?.date ?? .now
        self.category = transaction?.category ?? .other
        self.memo = transaction?.memo ?? ""
        self.businessRatioPercent = transaction?.businessRatioPercent ?? 100
    }

    func save(context: ModelContext) throws {
        guard let amount, amount > 0 else { return }

        if let existingTransaction {
            existingTransaction.amount = amount
            existingTransaction.date = date
            existingTransaction.category = category
            existingTransaction.memo = memo
            existingTransaction.businessRatioPercent = businessRatioPercent
            existingTransaction.updatedAt = .now
        } else {
            context.insert(
                ExpenseTransaction(
                    amount: amount,
                    date: date,
                    category: category,
                    memo: memo,
                    businessRatioPercent: businessRatioPercent
                )
            )
        }
        try context.save()
    }
}
