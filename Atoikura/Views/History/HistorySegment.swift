import Foundation

enum HistorySegment: String, CaseIterable, Identifiable, Hashable {
    case all
    case income
    case expense

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "すべて"
        case .income: return "売上"
        case .expense: return "経費"
        }
    }
}
