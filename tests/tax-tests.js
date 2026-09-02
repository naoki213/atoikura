/**
 * 税計算エンジンのテスト。特に境界値を重点的に確認する。
 */
(function (global) {
  'use strict';

  const { test, assertEqual, assertTrue, assertFalse } = global.Atoikura.testing;
  const tax = global.Atoikura.tax;
  const rules = global.Atoikura.taxRules.TaxRules2026;

  function baseProfile(overrides) {
    return Object.assign(
      {
        year: 2026,
        businessProfit: 0,
        filingType: 'white',
        blueReturnDeduction: 'notEligible',
        dependentsCount: 0,
        hasSpouse: false,
        isNationalPensionEnrolled: false,
        nationalHealthInsuranceAnnualAmount: 0,
        hasSetNationalHealthInsuranceAmount: false,
        businessTaxCategory: 'rate5Percent'
      },
      overrides || {}
    );
  }

  // --- 端数処理 -----------------------------------------------------------

  test('課税所得は1,000円未満を切り捨てる', () => {
    assertEqual(tax.floorTaxableIncome(0), 0);
    assertEqual(tax.floorTaxableIncome(1), 0);
    assertEqual(tax.floorTaxableIncome(999), 0);
    assertEqual(tax.floorTaxableIncome(1000), 1000);
    assertEqual(tax.floorTaxableIncome(1001), 1000);
    assertEqual(tax.floorTaxableIncome(1999), 1000);
    assertEqual(tax.floorTaxableIncome(2000), 2000);
  });

  test('税額は100円未満を切り捨てる', () => {
    assertEqual(tax.floorTaxAmount(0), 0);
    assertEqual(tax.floorTaxAmount(1), 0);
    assertEqual(tax.floorTaxAmount(99), 0);
    assertEqual(tax.floorTaxAmount(100), 100);
    assertEqual(tax.floorTaxAmount(199), 100);
    assertEqual(tax.floorTaxAmount(200), 200);
  });

  test('マイナスの金額は0円として扱う', () => {
    assertEqual(tax.floorTaxableIncome(-1), 0);
    assertEqual(tax.floorTaxAmount(-100), 0);
  });

  // --- 基礎控除の区分境界 --------------------------------------------------

  test('所得税の基礎控除は合計所得金額の区分境界で切り替わる', () => {
    assertEqual(rules.incomeTaxBasicDeduction(0), 950000);
    assertEqual(rules.incomeTaxBasicDeduction(1320000), 950000);
    assertEqual(rules.incomeTaxBasicDeduction(1320001), 880000);
    assertEqual(rules.incomeTaxBasicDeduction(3360000), 880000);
    assertEqual(rules.incomeTaxBasicDeduction(3360001), 680000);
    assertEqual(rules.incomeTaxBasicDeduction(4890000), 680000);
    assertEqual(rules.incomeTaxBasicDeduction(4890001), 670000);
    assertEqual(rules.incomeTaxBasicDeduction(6550000), 670000);
    assertEqual(rules.incomeTaxBasicDeduction(6550001), 620000);
    assertEqual(rules.incomeTaxBasicDeduction(23500000), 620000);
    assertEqual(rules.incomeTaxBasicDeduction(23500001), 480000);
    assertEqual(rules.incomeTaxBasicDeduction(25000000), 160000);
    assertEqual(rules.incomeTaxBasicDeduction(25000001), 0);
  });

  test('住民税の基礎控除は所得税より5万円低い', () => {
    assertEqual(rules.residentTaxBasicDeduction(0), 900000);
    assertEqual(rules.residentTaxBasicDeduction(5000000), 620000);
    assertEqual(rules.residentTaxBasicDeduction(25000001), 0);
  });

  test('青色申告特別控除の金額', () => {
    assertEqual(rules.blueReturnDeductionAmount('notEligible'), 0);
    assertEqual(rules.blueReturnDeductionAmount('simplifiedBookkeeping'), 100000);
    assertEqual(rules.blueReturnDeductionAmount('doubleEntryPaperFiling'), 550000);
    assertEqual(rules.blueReturnDeductionAmount('doubleEntryElectronicFiling'), 650000);
  });

  // --- 税率区分の境界 ------------------------------------------------------

  test('課税所得0円は最低税率の区分になる', () => {
    assertEqual(tax.applicableBracket(rules, 0).rateBp, 500);
  });

  test('課税所得1円は最低税率の区分になる', () => {
    assertEqual(tax.applicableBracket(rules, 1).rateBp, 500);
  });

  test('税率区分の境界直前は低いほうの税率', () => {
    assertEqual(tax.applicableBracket(rules, 1949000).rateBp, 500);
  });

  test('税率区分の境界ちょうどは低いほうの税率（境界を含む）', () => {
    assertEqual(tax.applicableBracket(rules, 1950000).rateBp, 500);
  });

  test('税率区分の境界直後は高いほうの税率', () => {
    assertEqual(tax.applicableBracket(rules, 1951000).rateBp, 1000);
  });

  test('最高税率の区分には上限が無い', () => {
    const bracket = tax.applicableBracket(rules, 100000000);
    assertEqual(bracket.rateBp, 4500);
    assertEqual(bracket.upTo, null);
  });

  // --- 所得税の計算フロー --------------------------------------------------

  test('事業所得0円なら所得税も0円', () => {
    const result = tax.calculate(baseProfile({ businessProfit: 0 }));
    assertEqual(result.incomeTax.taxableIncome, 0);
    assertEqual(result.incomeTax.total, 0);
  });

  test('課税所得が税率区分の境界ちょうどのとき5%が適用される', () => {
    // 合計所得2,830,000 − 基礎控除880,000 = 課税所得1,950,000（境界ちょうど）
    const result = tax.calculate(baseProfile({ businessProfit: 2830000 }));
    assertEqual(result.incomeTax.taxableIncome, 1950000);
    assertEqual(result.incomeTax.appliedRateBp, 500);
    assertEqual(result.incomeTax.incomeTaxBeforeSurtax, 97500);
  });

  test('課税所得が境界を1,000円超えると10%が適用される', () => {
    // 合計所得2,831,000 − 基礎控除880,000 = 課税所得1,951,000
    const result = tax.calculate(baseProfile({ businessProfit: 2831000 }));
    assertEqual(result.incomeTax.taxableIncome, 1951000);
    assertEqual(result.incomeTax.appliedRateBp, 1000);
    assertEqual(result.incomeTax.incomeTaxBeforeSurtax, 97600);
  });

  test('復興特別所得税は所得税額の2.1%として加算される', () => {
    const result = tax.calculate(baseProfile({ businessProfit: 2830000 }));
    assertEqual(result.incomeTax.reconstructionSurtax, Math.floor((97500 * 210) / 10000));
    assertEqual(result.incomeTax.total, tax.floorTaxAmount(97500 + 2047));
  });

  // --- 青色申告特別控除 ----------------------------------------------------

  test('青色申告特別控除は合計所得金額から差し引かれる', () => {
    const result = tax.calculate(
      baseProfile({
        businessProfit: 5000000,
        filingType: 'blue',
        blueReturnDeduction: 'doubleEntryElectronicFiling'
      })
    );
    assertEqual(result.incomeTax.blueReturnDeduction, 650000);
    assertEqual(result.incomeTax.totalIncome, 5000000 - 650000);
  });

  test('青色申告特別控除で合計所得金額がマイナスにはならない', () => {
    const result = tax.calculate(
      baseProfile({
        businessProfit: 100000,
        filingType: 'blue',
        blueReturnDeduction: 'doubleEntryElectronicFiling'
      })
    );
    assertEqual(result.incomeTax.totalIncome, 0);
    assertEqual(result.incomeTax.total, 0);
  });

  test('白色申告なら青色申告特別控除の設定が残っていても控除されない', () => {
    const result = tax.calculate(
      baseProfile({
        businessProfit: 5000000,
        filingType: 'white',
        blueReturnDeduction: 'doubleEntryElectronicFiling'
      })
    );
    assertEqual(result.incomeTax.blueReturnDeduction, 0);
    assertEqual(result.incomeTax.totalIncome, 5000000);
  });

  // --- 住民税 --------------------------------------------------------------

  test('事業所得0円なら住民税も0円（均等割もかからない）', () => {
    const result = tax.calculate(baseProfile({ businessProfit: 0 }));
    assertEqual(result.residentTax.taxableIncome, 0);
    assertEqual(result.residentTax.perCapitaLevy, 0);
    assertEqual(result.residentTax.total, 0);
  });

  test('住民税の所得割は課税所得の10%、均等割は5,000円', () => {
    // 合計所得1,000,000 − 住民税の基礎控除900,000 = 課税所得100,000
    const result = tax.calculate(baseProfile({ businessProfit: 1000000 }));
    assertEqual(result.residentTax.taxableIncome, 100000);
    assertEqual(result.residentTax.incomeLevy, 10000);
    assertEqual(result.residentTax.perCapitaLevy, 5000);
    assertEqual(result.residentTax.total, 15000);
  });

  // --- 国民年金・国民健康保険 ----------------------------------------------

  test('国民年金は月額×12で計算する', () => {
    const result = tax.calculate(baseProfile({ isNationalPensionEnrolled: true }));
    assertEqual(result.nationalPension.monthlyAmount, 17920);
    assertEqual(result.nationalPension.annualAmount, 17920 * 12);
  });

  test('国民年金に未加入なら0円', () => {
    const result = tax.calculate(baseProfile({ isNationalPensionEnrolled: false }));
    assertEqual(result.nationalPension.annualAmount, 0);
  });

  test('国民健康保険は未設定なら0円として扱い、未設定であることを保持する', () => {
    const result = tax.calculate(
      baseProfile({
        nationalHealthInsuranceAnnualAmount: 300000,
        hasSetNationalHealthInsuranceAmount: false
      })
    );
    assertEqual(result.nationalHealthInsurance.annualAmount, 0);
    assertFalse(result.nationalHealthInsurance.isUserProvided);
  });

  test('国民健康保険は入力済みならその金額をそのまま使う', () => {
    const result = tax.calculate(
      baseProfile({
        nationalHealthInsuranceAnnualAmount: 300000,
        hasSetNationalHealthInsuranceAmount: true
      })
    );
    assertEqual(result.nationalHealthInsurance.annualAmount, 300000);
    assertTrue(result.nationalHealthInsurance.isUserProvided);
  });

  test('社会保険料は所得控除として課税所得を減らす', () => {
    const withoutInsurance = tax.calculate(baseProfile({ businessProfit: 5000000 }));
    const withInsurance = tax.calculate(
      baseProfile({ businessProfit: 5000000, isNationalPensionEnrolled: true })
    );
    assertTrue(withInsurance.incomeTax.taxableIncome < withoutInsurance.incomeTax.taxableIncome);
  });

  // --- 個人事業税 ----------------------------------------------------------

  test('事業所得が事業主控除以下なら個人事業税は0円', () => {
    assertEqual(tax.calculate(baseProfile({ businessProfit: 2000000 })).businessTax.total, 0);
    assertEqual(tax.calculate(baseProfile({ businessProfit: 2900000 })).businessTax.total, 0);
  });

  test('事業主控除を超えた分に税率がかかる', () => {
    const result = tax.calculate(baseProfile({ businessProfit: 3000000 }));
    assertEqual(result.businessTax.taxableAmount, 100000);
    assertEqual(result.businessTax.total, 5000);
  });

  test('非課税業種なら個人事業税は0円', () => {
    const result = tax.calculate(
      baseProfile({ businessProfit: 10000000, businessTaxCategory: 'exempt' })
    );
    assertEqual(result.businessTax.total, 0);
  });

  test('個人事業税は青色申告特別控除を差し引く前の事業所得に課税される', () => {
    const result = tax.calculate(
      baseProfile({
        businessProfit: 3000000,
        filingType: 'blue',
        blueReturnDeduction: 'doubleEntryElectronicFiling'
      })
    );
    assertEqual(result.businessTax.taxableAmount, 100000);
    assertEqual(result.businessTax.total, 5000);
  });

  // --- 全体 ----------------------------------------------------------------

  test('合計額は各項目の合計と一致する', () => {
    const result = tax.calculate(
      baseProfile({
        businessProfit: 5390000,
        filingType: 'blue',
        blueReturnDeduction: 'doubleEntryElectronicFiling',
        isNationalPensionEnrolled: true,
        nationalHealthInsuranceAnnualAmount: 300000,
        hasSetNationalHealthInsuranceAmount: true
      })
    );
    assertEqual(
      result.total,
      result.incomeTax.total +
        result.residentTax.total +
        result.nationalPension.annualAmount +
        result.nationalHealthInsurance.annualAmount +
        result.businessTax.total
    );
  });

  test('未対応の年度は直近のルールにフォールバックし、使用した年度が分かる', () => {
    const result = tax.calculate(baseProfile({ year: 2030, businessProfit: 3000000 }));
    assertEqual(result.ruleSetYear, 2026);
  });
})(typeof globalThis !== 'undefined' ? globalThis : this);
