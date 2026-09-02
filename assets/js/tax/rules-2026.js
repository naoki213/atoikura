/**
 * 2026年分（令和8年分）の税制ルール。
 *
 * 税率・控除額などの「数値」はこのファイルだけに書く。View や計算エンジン側に
 * マジックナンバーを散らさないこと。新しい年度に対応するときは rules-2027.js を
 * 追加して registry に登録する。
 *
 * 税率は浮動小数点の誤差を避けるため basis point（bp, 1bp = 0.01%）の整数で保持する。
 * 例: 5% = 500bp、10% = 1000bp、2.1% = 210bp
 *
 * 数値の根拠と要検証項目は DEVELOPMENT.md の「税制データの検証状況」を参照。
 */
(function (global) {
  'use strict';

  const TaxRules2026 = {
    year: 2026,

    // --- 所得税 -------------------------------------------------------------

    /** 所得税の速算表（課税所得の低い順）。upTo が null なら上限なし。 */
    incomeTaxBrackets: [
      { upTo: 1950000, rateBp: 500, deduction: 0 },
      { upTo: 3300000, rateBp: 1000, deduction: 97500 },
      { upTo: 6950000, rateBp: 2000, deduction: 427500 },
      { upTo: 9000000, rateBp: 2300, deduction: 636000 },
      { upTo: 18000000, rateBp: 3300, deduction: 1536000 },
      { upTo: 40000000, rateBp: 4000, deduction: 2796000 },
      { upTo: null, rateBp: 4500, deduction: 4796000 }
    ],

    /** 合計所得金額に応じた所得税の基礎控除額（要検証: DEVELOPMENT.md 参照）。 */
    incomeTaxBasicDeduction(totalIncome) {
      if (totalIncome <= 1320000) return 950000;
      if (totalIncome <= 3360000) return 880000;
      if (totalIncome <= 4890000) return 680000;
      if (totalIncome <= 6550000) return 670000;
      if (totalIncome <= 23500000) return 620000;
      if (totalIncome <= 24000000) return 480000;
      if (totalIncome <= 24500000) return 320000;
      if (totalIncome <= 25000000) return 160000;
      return 0;
    },

    /** 住民税の基礎控除は所得税より一律5万円低いものとして単純化している（要検証）。 */
    residentTaxBasicDeduction(totalIncome) {
      return Math.max(0, this.incomeTaxBasicDeduction(totalIncome) - 50000);
    },

    /**
     * 配偶者控除・扶養控除は、所得制限や年齢区分（特定扶養・老人扶養等）を
     * 考慮しない簡略化版（一律金額）。UI 上で「概算」であることを明示すること。
     */
    incomeTaxSpouseDeduction: 380000,
    incomeTaxDependentDeduction: 380000,
    residentTaxSpouseDeduction: 330000,
    residentTaxDependentDeduction: 330000,

    /** 復興特別所得税率（2037年まで継続する安定した制度）。2.1% */
    reconstructionSurtaxBp: 210,

    /** 青色申告特別控除額。 */
    blueReturnDeductionAmount(type) {
      switch (type) {
        case 'simplifiedBookkeeping':
          return 100000;
        case 'doubleEntryPaperFiling':
          return 550000;
        case 'doubleEntryElectronicFiling':
          return 650000;
        default:
          return 0;
      }
    },

    // --- 住民税 -------------------------------------------------------------

    /** 所得割率 10%（都道府県4% + 市区町村6%相当）。 */
    residentTaxIncomeRateBp: 1000,

    /** 均等割（年額）。標準額の概算（森林環境税を含む）。自治体により若干異なる。 */
    residentTaxPerCapita: 5000,

    // --- 国民年金 -----------------------------------------------------------

    /** 令和8年度（2026年4月〜2027年3月）の月額。1〜3月分は考慮しない簡略計算。 */
    nationalPensionMonthlyAmount: 17920,

    // --- 個人事業税 ---------------------------------------------------------

    /** 事業主控除（年額）。 */
    businessTaxDeduction: 2900000,

    /** 業種区分ごとの税率。 */
    businessTaxRateBp(category) {
      switch (category) {
        case 'rate3Percent':
          return 300;
        case 'rate4Percent':
          return 400;
        case 'rate5Percent':
          return 500;
        default:
          return 0; // exempt（非課税業種）
      }
    }
  };

  /**
   * 年度からルールセットを引く。未対応の年度は直近の実装にフォールバックするが、
   * 計算結果の ruleSetYear で実際に使われたルールの年度を確認できる。
   */
  function ruleSetForYear(year) {
    switch (year) {
      case 2026:
        return TaxRules2026;
      default:
        return TaxRules2026;
    }
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.taxRules = {
    TaxRules2026,
    ruleSetForYear
  };
})(typeof globalThis !== 'undefined' ? globalThis : this);
