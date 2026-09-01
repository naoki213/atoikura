import Foundation

/// 個人事業税の税率区分。
///
/// 個人事業税の税率は法定業種ごとに細かく分かれる（70業種以上）が、
/// Ver1.0では個人事業主・フリーランスに多い区分に単純化して提供する。
/// 正確な業種区分の判定が必要な場合は税務署・都道府県税事務所へ確認するよう
/// UI上で案内すること。
public enum BusinessTaxCategory: String, Codable, CaseIterable, Sendable {
    /// 非課税業種（著述業など、個人事業税がかからない業種）。
    case exempt

    /// 第2種事業などに多い4%区分（畜産業・水産業等）。
    case rate4Percent

    /// 第1種・第3種事業に多い5%区分（物品販売業、請負業、デザイン業、コンサルタント業等）。
    /// 多くのフリーランス業種はここに該当する。
    case rate5Percent

    /// 第3種事業のうち軽減税率が適用される区分（あんま・マッサージ指圧師業等）。
    case rate3Percent

    public var displayName: String {
        switch self {
        case .exempt: return "非課税業種（例: 著述業）"
        case .rate4Percent: return "4%区分（例: 畜産業・水産業）"
        case .rate5Percent: return "5%区分（例: 請負業・デザイン業・コンサルタント業など多くの業種）"
        case .rate3Percent: return "3%区分（例: あんま・マッサージ指圧師業）"
        }
    }
}
