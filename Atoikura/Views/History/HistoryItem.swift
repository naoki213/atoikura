import Foundation
import SwiftData
import SwiftUI

/// 履歴画面で売上・経費を同じ一覧に並べるための表示用ラッパー。
/// SwiftDataモデル自体は変更せず、表示に必要な情報だけをここで導出する。
enum HistoryItem: Identifiable, Hashable {
    case income(IncomeTransaction)
    case expense(ExpenseTransaction)

    var id: PersistentIdentifier {
        switch self {
        case .income(let transaction): return transaction.id
        case .expense(let transaction): return transaction.id
        }
    }

    var date: Date {
        switch self {
        case .income(let transaction): return transaction.date
        case .expense(let transaction): return transaction.date
        }
    }

    var title: String {
        switch self {
        case .income(let transaction):
            return transaction.clientName.isEmpty ? "売上" : transaction.clientName
        case .expense(let transaction):
            return transaction.category.displayName
        }
    }

    var subtitle: String? {
        switch self {
        case .income(let transaction):
            return transaction.isPaid ? nil : "未入金"
        case .expense:
            return nil
        }
    }

    /// 売上はプラス、経費はマイナスで表示する。
    var signedAmount: Decimal {
        switch self {
        case .income(let transaction): return transaction.amount
        case .expense(let transaction): return -transaction.amount
        }
    }

    var symbolName: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense(let transaction): return transaction.category.symbolName
        }
    }

    var tintColor: Color {
        switch self {
        case .income: return .blue
        case .expense: return .secondary
        }
    }
}
