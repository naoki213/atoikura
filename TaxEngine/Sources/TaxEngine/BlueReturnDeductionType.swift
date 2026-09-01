import Foundation

/// 青色申告特別控除の適用区分。
///
/// 白色申告の場合は常に `.notEligible`（控除なし）。
/// 実際の控除額は ``TaxRuleSet/blueReturnDeductionAmount(for:)`` が年度ごとのルールに基づいて返す。
public enum BlueReturnDeductionType: String, Codable, CaseIterable, Sendable {
    /// 対象外（白色申告、または要件を満たさない場合）。控除額 0円。
    case notEligible

    /// 簡易な記帳のみ（複式簿記でない）。控除額 10万円。
    case simplifiedBookkeeping

    /// 複式簿記＋貸借対照表等を添付。e-Taxや電子帳簿保存を行っていない。控除額 55万円。
    case doubleEntryPaperFiling

    /// 複式簿記＋貸借対照表等を添付し、e-Taxによる申告または優良な電子帳簿保存を行っている。控除額 65万円。
    case doubleEntryElectronicFiling

    public var displayName: String {
        switch self {
        case .notEligible: return "適用なし"
        case .simplifiedBookkeeping: return "10万円控除（簡易な記帳）"
        case .doubleEntryPaperFiling: return "55万円控除（複式簿記・書面提出）"
        case .doubleEntryElectronicFiling: return "65万円控除（複式簿記・e-Tax/電子帳簿）"
        }
    }
}
