import Foundation
import Observation
import SwiftData

/// 売上の新規追加・編集を扱う。
@Observable
final class IncomeEntryViewModel {
    var amount: Decimal?
    var date: Date
    var clientName: String
    var memo: String
    var category: String
    var isPaid: Bool

    private let existingTransaction: IncomeTransaction?

    var isEditing: Bool { existingTransaction != nil }

    /// 既存の詳細項目に何か入力済みなら、編集時は最初から詳細セクションを開いておく。
    var hasDetailInput: Bool {
        !clientName.isEmpty || !memo.isEmpty || !category.isEmpty || !isPaid
    }

    var isSaveDisabled: Bool {
        guard let amount else { return true }
        return amount <= 0
    }

    init(transaction: IncomeTransaction? = nil) {
        self.existingTransaction = transaction
        self.amount = transaction?.amount
        self.date = transaction?.date ?? .now
        self.clientName = transaction?.clientName ?? ""
        self.memo = transaction?.memo ?? ""
        self.category = transaction?.category ?? ""
        self.isPaid = transaction?.isPaid ?? true
    }

    func save(context: ModelContext) throws {
        guard let amount, amount > 0 else { return }

        if let existingTransaction {
            existingTransaction.amount = amount
            existingTransaction.date = date
            existingTransaction.clientName = clientName
            existingTransaction.memo = memo
            existingTransaction.category = category
            existingTransaction.isPaid = isPaid
            existingTransaction.updatedAt = .now
        } else {
            context.insert(
                IncomeTransaction(
                    amount: amount,
                    date: date,
                    clientName: clientName,
                    memo: memo,
                    category: category,
                    isPaid: isPaid
                )
            )
        }
        try context.save()
    }
}
