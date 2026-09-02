/**
 * 税計算エンジン。UI（DOM）に一切依存しない純粋な計算だけを置く。
 *
 * 金額はすべて「円単位の整数」で扱う（日本円に小数は無いため、整数演算に統一して
 * 浮動小数点の誤差を避ける）。税率は basis point の整数で受け取り、
 * 「金額 × bp ÷ 10000」の順で計算してから切り捨てる。
 */
(function (global) {
  'use strict';

  const rules = global.Atoikura.taxRules;

  /** value を unit の倍数へ切り捨てる。マイナスは 0 として扱う。 */
  function floorToUnit(value, unit) {
    if (!(value > 0)) return 0;
    return Math.floor(value / unit) * unit;
  }

  /** 課税所得の端数処理（1,000円未満切り捨て）。 */
  function floorTaxableIncome(value) {
    return floorToUnit(value, 1000);
  }

  /** 税額の端数処理（100円未満切り捨て）。 */
  function floorTaxAmount(value) {
    return floorToUnit(value, 100);
  }

  /** 金額 × 税率(bp)。整数のまま計算してから切り捨てる。 */
  function applyRateBp(amount, rateBp) {
    return Math.floor((amount * rateBp) / 10000);
  }

  /** 課税所得に対応する速算表の区分を返す。 */
  function applicableBracket(ruleSet, taxableIncome) {
    for (const bracket of ruleSet.incomeTaxBrackets) {
      if (bracket.upTo === null || taxableIncome <= bracket.upTo) {
        return bracket;
      }
    }
    return ruleSet.incomeTaxBrackets[ruleSet.incomeTaxBrackets.length - 1];
  }

  /**
   * 青色申告特別控除の実効額。
   * 白色申告の場合は、設定に何が残っていても控除は 0 円として扱う。
   */
  function effectiveBlueDeduction(ruleSet, profile) {
    if (profile.filingType !== 'blue') return 0;
    return ruleSet.blueReturnDeductionAmount(profile.blueReturnDeduction);
  }

  /** 国民年金（月額 × 12 の単純計算）。 */
  function calculateNationalPension(ruleSet, profile) {
    if (!profile.isNationalPensionEnrolled) {
      return { isEnrolled: false, monthlyAmount: 0, annualAmount: 0 };
    }
    const monthlyAmount = ruleSet.nationalPensionMonthlyAmount;
    return { isEnrolled: true, monthlyAmount, annualAmount: monthlyAmount * 12 };
  }

  /**
   * 国民健康保険。自治体ごとに料率・均等割・上限額が大きく異なり所得だけから
   * 一意に算出できないため、自動計算はせずユーザーが入力した年額をそのまま使う。
   */
  function calculateNationalHealthInsurance(profile) {
    const isUserProvided = Boolean(profile.hasSetNationalHealthInsuranceAmount);
    return {
      annualAmount: isUserProvided ? profile.nationalHealthInsuranceAnnualAmount || 0 : 0,
      isUserProvided
    };
  }

  /** 所得税（＋復興特別所得税）。 */
  function calculateIncomeTax(ruleSet, profile, socialInsuranceDeduction) {
    const blueReturnDeduction = effectiveBlueDeduction(ruleSet, profile);
    const totalIncome = Math.max(0, profile.businessProfit - blueReturnDeduction);

    const basicDeduction = ruleSet.incomeTaxBasicDeduction(totalIncome);
    const spouseDeduction = profile.hasSpouse ? ruleSet.incomeTaxSpouseDeduction : 0;
    const dependentDeduction =
      (profile.dependentsCount || 0) * ruleSet.incomeTaxDependentDeduction;

    const totalDeductions =
      basicDeduction + spouseDeduction + dependentDeduction + socialInsuranceDeduction;
    const taxableIncome = floorTaxableIncome(totalIncome - totalDeductions);

    const bracket = applicableBracket(ruleSet, taxableIncome);
    const incomeTaxBeforeSurtax = Math.max(
      0,
      applyRateBp(taxableIncome, bracket.rateBp) - bracket.deduction
    );
    const reconstructionSurtax = applyRateBp(
      incomeTaxBeforeSurtax,
      ruleSet.reconstructionSurtaxBp
    );

    return {
      totalIncome,
      blueReturnDeduction,
      basicDeduction,
      spouseDeduction,
      dependentDeduction,
      socialInsuranceDeduction,
      taxableIncome,
      appliedRateBp: bracket.rateBp,
      appliedBracketDeduction: bracket.deduction,
      incomeTaxBeforeSurtax,
      reconstructionSurtax,
      total: floorTaxAmount(incomeTaxBeforeSurtax + reconstructionSurtax)
    };
  }

  /**
   * 住民税。
   * 実際の住民税は前年の所得に対して翌年度課税されるが、「今の所得水準ならこれくらい」
   * という直感的な概算を優先し、同一年内の所得から計算している（時期のズレは考慮しない）。
   */
  function calculateResidentTax(ruleSet, profile, socialInsuranceDeduction) {
    const blueReturnDeduction = effectiveBlueDeduction(ruleSet, profile);
    const totalIncome = Math.max(0, profile.businessProfit - blueReturnDeduction);

    const basicDeduction = ruleSet.residentTaxBasicDeduction(totalIncome);
    const spouseDeduction = profile.hasSpouse ? ruleSet.residentTaxSpouseDeduction : 0;
    const dependentDeduction =
      (profile.dependentsCount || 0) * ruleSet.residentTaxDependentDeduction;

    const totalDeductions =
      basicDeduction + spouseDeduction + dependentDeduction + socialInsuranceDeduction;
    const taxableIncome = floorTaxableIncome(totalIncome - totalDeductions);

    const incomeLevy = floorTaxAmount(
      applyRateBp(taxableIncome, ruleSet.residentTaxIncomeRateBp)
    );
    const perCapitaLevy = taxableIncome > 0 ? ruleSet.residentTaxPerCapita : 0;

    return {
      totalIncome,
      basicDeduction,
      spouseDeduction,
      dependentDeduction,
      socialInsuranceDeduction,
      taxableIncome,
      incomeLevy,
      perCapitaLevy,
      total: incomeLevy + perCapitaLevy
    };
  }

  /**
   * 個人事業税。
   * 青色申告特別控除を差し引く「前」の事業所得に対して課税される点に注意
   * （所得税・住民税とは課税標準の考え方が異なる）。
   */
  function calculateBusinessTax(ruleSet, profile) {
    const deduction = ruleSet.businessTaxDeduction;
    const taxableAmount = Math.max(0, profile.businessProfit - deduction);
    const rateBp = ruleSet.businessTaxRateBp(profile.businessTaxCategory);
    return {
      taxableAmount,
      rateBp,
      deduction,
      total: floorTaxAmount(applyRateBp(taxableAmount, rateBp))
    };
  }

  /**
   * 1年分の税金・社会保険をまとめて概算する。
   * @param {object} profile 事業所得や申告方法などの入力
   * @returns {object} 税額と、その根拠（課税所得・適用控除・適用税率・計算年度）
   */
  function calculate(profile) {
    const ruleSet = rules.ruleSetForYear(profile.year);

    const nationalPension = calculateNationalPension(ruleSet, profile);
    const nationalHealthInsurance = calculateNationalHealthInsurance(profile);
    const socialInsuranceDeduction =
      nationalPension.annualAmount + nationalHealthInsurance.annualAmount;

    const incomeTax = calculateIncomeTax(ruleSet, profile, socialInsuranceDeduction);
    const residentTax = calculateResidentTax(ruleSet, profile, socialInsuranceDeduction);
    const businessTax = calculateBusinessTax(ruleSet, profile);

    return {
      year: profile.year,
      ruleSetYear: ruleSet.year,
      incomeTax,
      residentTax,
      nationalPension,
      nationalHealthInsurance,
      businessTax,
      total:
        incomeTax.total +
        residentTax.total +
        nationalPension.annualAmount +
        nationalHealthInsurance.annualAmount +
        businessTax.total
    };
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.tax = {
    calculate,
    // テストから直接検証できるように内部関数も公開する
    floorTaxableIncome,
    floorTaxAmount,
    applyRateBp,
    applicableBracket
  };
})(typeof globalThis !== 'undefined' ? globalThis : this);
