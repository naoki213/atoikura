import Foundation

/// 確定申告の方式。
public enum FilingType: String, Codable, CaseIterable, Hashable, Sendable {
    case blue
    case white

    public var displayName: String {
        switch self {
        case .blue: return "青色申告"
        case .white: return "白色申告"
        }
    }
}
