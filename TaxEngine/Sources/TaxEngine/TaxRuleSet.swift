import Foundation

/// 年度ごとの税制ルール（税率・控除額テーブル）を表すプロトコル。
///
/// 新しい年度の税制に対応する場合は、このプロトコルに準拠した型
/// （例: `TaxRules2027`）を追加し、`TaxRuleSetRegistry` に登録する。
/// 税率・控除額などのマジックナンバーはこのプロトコルの実装にのみ書き、
/// Calculator や View には直接書かない。
public protocol TaxRuleSet: Sendable {
    var year: Int { get }

    /// 所得税の速算表（課税所得の低い順）。
    var incomeTaxBrackets: [IncomeTaxBracket] { get }

    /// 合計所得金額に応じた所得税の基礎控除額。
    func incomeTaxBasicDeduction(totalIncome: Decimal) -> Decimal

    /// 合計所得金額に応じた住民税の基礎控除額。
    func residentTaxBasicDeduction(totalIncome: Decimal) -> Decimal

    /// 住民税の所得割率（例: 0.10 = 10%）。
    var residentTaxIncomeRate: Decimal { get }

    /// 住民税の均等割（年額、全国的な標準額の概算）。
    var residentTaxPerCapita: Decimal { get }

    /// 所得税の配偶者控除額（Ver1.0では所得制限を考慮せず一律の金額を用いる簡略化版）。
    var incomeTaxSpouseDeduction: Decimal { get }

    /// 所得税の扶養控除額（Ver1.0では年齢区分を考慮せず一律の金額を用いる簡略化版、1人あたり）。
    var incomeTaxDependentDeduction: Decimal { get }

    /// 住民税の配偶者控除額（簡略化版）。
    var residentTaxSpouseDeduction: Decimal { get }

    /// 住民税の扶養控除額（簡略化版、1人あたり）。
    var residentTaxDependentDeduction: Decimal { get }

    /// 復興特別所得税率（例: 0.021 = 2.1%）。
    var reconstructionSurtaxRate: Decimal { get }

    /// 青色申告特別控除額。
    func blueReturnDeductionAmount(for type: BlueReturnDeductionType) -> Decimal

    /// 国民年金保険料（月額）。
    var nationalPensionMonthlyAmount: Decimal { get }

    /// 個人事業税の事業主控除（年額）。
    var businessTaxDeduction: Decimal { get }

    /// 個人事業税の税率区分ごとの税率。
    func businessTaxRate(for category: BusinessTaxCategory) -> Decimal
}
