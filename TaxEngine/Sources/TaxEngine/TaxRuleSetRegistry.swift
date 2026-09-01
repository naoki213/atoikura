import Foundation

/// 年度を指定してルールセットを取得するレジストリ。
///
/// 新しい年度に対応する場合は、対応する `TaxRulesYYYY` を実装した上で
/// このswitch文にケースを追加すること。未対応の年度は直近の実装済みルールに
/// フォールバックするが、これは概算としての妥当性を優先した措置であり、
/// 正式にサポートしている年度ではない点に注意（`TaxCalculationResult.ruleSetYear`
/// で実際に使われたルールの年度を確認できる）。
public enum TaxRuleSetRegistry {
    public static func ruleSet(for year: Int) -> TaxRuleSet {
        switch year {
        case 2026:
            return TaxRules2026()
        default:
            return TaxRules2026()
        }
    }
}
