import Foundation

/// 経費のカテゴリー。税計算には使用せず、履歴の分類・表示のみに使う。
enum ExpenseCategory: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case purchases          // 仕入
    case supplies           // 消耗品
    case communication       // 通信費
    case travel              // 交通費
    case advertising          // 広告宣伝費
    case outsourcing          // 外注費
    case rent                 // 地代家賃
    case utilities            // 水道光熱費
    case entertainment        // 接待交際費
    case other                 // その他

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .purchases: return "仕入"
        case .supplies: return "消耗品"
        case .communication: return "通信費"
        case .travel: return "交通費"
        case .advertising: return "広告宣伝費"
        case .outsourcing: return "外注費"
        case .rent: return "地代家賃"
        case .utilities: return "水道光熱費"
        case .entertainment: return "接待交際費"
        case .other: return "その他"
        }
    }

    var symbolName: String {
        switch self {
        case .purchases: return "shippingbox"
        case .supplies: return "pencil.and.ruler"
        case .communication: return "antenna.radiowaves.left.and.right"
        case .travel: return "car"
        case .advertising: return "megaphone"
        case .outsourcing: return "person.2"
        case .rent: return "house"
        case .utilities: return "bolt"
        case .entertainment: return "cup.and.saucer"
        case .other: return "ellipsis.circle"
        }
    }
}
