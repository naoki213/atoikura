import Foundation

/// 2026年分（令和8年分）の税制ルール。
///
/// 数値の根拠・不確実な項目については、リポジトリルートの `DEVELOPMENT.md` の
/// 「税制データの検証状況」を必ず参照すること。特に基礎控除の多段階テーブルは
/// 一次情報（国税庁）への直接アクセスができない状況で複数の二次情報を突き合わせて
/// 実装したものであり、App Store公開前に必ず再検証が必要。
public struct TaxRules2026: TaxRuleSet {
    public let year = 2026

    public init() {}

    // MARK: - 所得税

    /// 所得税の速算表。長年変更のない安定した制度部分（国税庁タックスアンサー No.2260）。
    public let incomeTaxBrackets: [IncomeTaxBracket] = [
        IncomeTaxBracket(upperBound: 1_950_000, rate: 0.05, baseDeduction: 0),
        IncomeTaxBracket(upperBound: 3_300_000, rate: 0.10, baseDeduction: 97_500),
        IncomeTaxBracket(upperBound: 6_950_000, rate: 0.20, baseDeduction: 427_500),
        IncomeTaxBracket(upperBound: 9_000_000, rate: 0.23, baseDeduction: 636_000),
        IncomeTaxBracket(upperBound: 18_000_000, rate: 0.33, baseDeduction: 1_536_000),
        IncomeTaxBracket(upperBound: 40_000_000, rate: 0.40, baseDeduction: 2_796_000),
        IncomeTaxBracket(upperBound: nil, rate: 0.45, baseDeduction: 4_796_000)
    ]

    /// 令和8年度税制改正による、合計所得金額に応じた基礎控除の多段階テーブル（要検証、DEVELOPMENT.md参照）。
    public func incomeTaxBasicDeduction(totalIncome: Decimal) -> Decimal {
        switch totalIncome {
        case ...1_320_000: return 950_000
        case ...3_360_000: return 880_000
        case ...4_890_000: return 680_000
        case ...6_550_000: return 670_000
        case ...23_500_000: return 620_000
        case ...24_000_000: return 480_000
        case ...24_500_000: return 320_000
        case ...25_000_000: return 160_000
        default: return 0
        }
    }

    /// 住民税の基礎控除は、所得税の基礎控除より一律5万円低いものとして単純化している（要検証）。
    public func residentTaxBasicDeduction(totalIncome: Decimal) -> Decimal {
        max(0, incomeTaxBasicDeduction(totalIncome: totalIncome) - 50_000)
    }

    /// 配偶者控除・扶養控除は、所得制限や年齢区分（特定扶養・老人扶養等）を考慮しない
    /// 簡略化版（一律金額）。正確な金額が必要な場合は税理士等に確認するようアプリ内で案内する。
    public let incomeTaxSpouseDeduction: Decimal = 380_000
    public let incomeTaxDependentDeduction: Decimal = 380_000
    public let residentTaxSpouseDeduction: Decimal = 330_000
    public let residentTaxDependentDeduction: Decimal = 330_000

    /// 復興特別所得税率（2037年まで継続、安定した制度）。
    public let reconstructionSurtaxRate: Decimal = 0.021

    public func blueReturnDeductionAmount(for type: BlueReturnDeductionType) -> Decimal {
        switch type {
        case .notEligible: return 0
        case .simplifiedBookkeeping: return 100_000
        case .doubleEntryPaperFiling: return 550_000
        case .doubleEntryElectronicFiling: return 650_000
        }
    }

    // MARK: - 住民税

    /// 所得割率。都道府県4%＋市区町村6%相当（自治体による差異はごく一部を除き標準的に一律10%）。
    public let residentTaxIncomeRate: Decimal = 0.10

    /// 均等割（年額）。標準額の概算（森林環境税を含む）。実際の金額は自治体により若干異なる。
    public let residentTaxPerCapita: Decimal = 5_000

    // MARK: - 国民年金

    /// 令和8年度（2026年4月〜2027年3月）の月額。1〜3月分（令和7年度料率）は考慮しない簡略計算（要検証）。
    public let nationalPensionMonthlyAmount: Decimal = 17_920

    // MARK: - 個人事業税

    /// 事業主控除（年額）。
    public let businessTaxDeduction: Decimal = 2_900_000

    public func businessTaxRate(for category: BusinessTaxCategory) -> Decimal {
        switch category {
        case .exempt: return 0
        case .rate3Percent: return 0.03
        case .rate4Percent: return 0.04
        case .rate5Percent: return 0.05
        }
    }
}
