/**
 * 年間集計・年間予測・「今年あと使えるお金」のテスト。
 */
(function (global) {
  'use strict';

  const { test, assertEqual, assertTrue, assertFalse } = global.Atoikura.testing;
  const services = global.Atoikura.services;

  function income(amount, date) {
    return { amount, date };
  }

  function expense(amount, date, businessRatioPercent) {
    return { amount, date, businessRatioPercent: businessRatioPercent ?? 100 };
  }

  // --- 年間集計 ------------------------------------------------------------

  test('対象年度の取引だけを集計する', () => {
    const actuals = services.annualActuals(
      2026,
      [income(1000000, '2026-03-01'), income(2000000, '2025-12-31')],
      [expense(100000, '2026-03-01', 50)],
      '2026-06-15'
    );
    assertEqual(actuals.totalRevenue, 1000000);
    assertEqual(actuals.totalExpense, 50000, '事業割合50%が適用される');
  });

  test('経費は事業割合を適用した金額で集計する', () => {
    assertEqual(services.deductibleExpenseAmount(expense(10000, '2026-01-01', 100)), 10000);
    assertEqual(services.deductibleExpenseAmount(expense(10000, '2026-01-01', 50)), 5000);
    assertEqual(services.deductibleExpenseAmount(expense(10000, '2026-01-01', 0)), 0);
  });

  test('今年なら経過月数は今月の月数になる', () => {
    const actuals = services.annualActuals(2026, [], [], '2026-06-15');
    assertEqual(actuals.elapsedMonths, 6);
  });

  test('過ぎた年度は経過月数12として扱う', () => {
    assertEqual(services.annualActuals(2025, [], [], '2026-06-15').elapsedMonths, 12);
  });

  test('まだ来ていない年度は経過月数0として扱う', () => {
    assertEqual(services.annualActuals(2027, [], [], '2026-06-15').elapsedMonths, 0);
  });

  test('日付は文字列で比較するので端末のタイムゾーンに影響されない', () => {
    // 年始・年末ちょうどの取引が、隣の年度へ吸われないことを確認する
    const actuals = services.annualActuals(
      2026,
      [income(100, '2026-01-01'), income(200, '2026-12-31'), income(400, '2027-01-01')],
      [],
      '2026-12-31'
    );
    assertEqual(actuals.totalRevenue, 300);
  });

  // --- 年間予測 ------------------------------------------------------------

  test('自動予測は実績を経過月数で年間換算する', () => {
    const actuals = { year: 2026, totalRevenue: 3000000, totalExpense: 600000, elapsedMonths: 6 };
    const forecast = services.annualForecast(actuals, null, null);
    assertEqual(forecast.revenueForecast, 6000000);
    assertEqual(forecast.expenseForecast, 1200000);
    assertFalse(forecast.isRevenueManual);
    assertFalse(forecast.isExpenseManual);
  });

  test('手動設定値があれば自動予測より優先される', () => {
    const actuals = { year: 2026, totalRevenue: 3000000, totalExpense: 600000, elapsedMonths: 6 };
    const forecast = services.annualForecast(actuals, 8000000, null);
    assertEqual(forecast.revenueForecast, 8000000);
    assertTrue(forecast.isRevenueManual);
    assertEqual(forecast.expenseForecast, 1200000);
    assertFalse(forecast.isExpenseManual);
  });

  test('手動設定値が0円でも手動として扱う', () => {
    const actuals = { year: 2026, totalRevenue: 3000000, totalExpense: 600000, elapsedMonths: 6 };
    const forecast = services.annualForecast(actuals, 0, 0);
    assertEqual(forecast.revenueForecast, 0);
    assertTrue(forecast.isRevenueManual);
  });

  test('経過月数0でもゼロ除算にならない', () => {
    const actuals = { year: 2027, totalRevenue: 0, totalExpense: 0, elapsedMonths: 0 };
    const forecast = services.annualForecast(actuals, null, null);
    assertEqual(forecast.revenueForecast, 0);
    assertEqual(forecast.expenseForecast, 0);
  });

  // --- 今年あと使えるお金 --------------------------------------------------

  function taxSettings(overrides) {
    return Object.assign(
      {
        blueReturnDeduction: 'doubleEntryElectronicFiling',
        dependentsCount: 0,
        hasSpouse: false,
        isNationalPensionEnrolled: true,
        nationalHealthInsuranceAnnualAmount: 300000,
        hasSetNationalHealthInsuranceAmount: true,
        businessTaxCategory: 'rate5Percent'
      },
      overrides || {}
    );
  }

  test('あと使えるお金 = 予想利益 − 税金社会保険 − 確保する資金', () => {
    const forecast = {
      year: 2026,
      revenueForecast: 6820000,
      expenseForecast: 1430000,
      isRevenueManual: false,
      isExpenseManual: false
    };
    const breakdown = services.allowanceBreakdown(
      forecast,
      { filingType: 'blue' },
      taxSettings(),
      { businessReserveAmount: 600000, otherReserveAmount: 0 }
    );

    assertEqual(breakdown.projectedProfit, 5390000);
    assertEqual(breakdown.taxAndSocialInsurance, breakdown.taxResult.total);
    assertEqual(
      breakdown.remainingAllowance,
      breakdown.projectedProfit - breakdown.taxAndSocialInsurance - 600000
    );
  });

  test('赤字のときは、あと使えるお金がマイナスのまま表示される', () => {
    const forecast = {
      year: 2026,
      revenueForecast: 1000000,
      expenseForecast: 2000000,
      isRevenueManual: false,
      isExpenseManual: false
    };
    const breakdown = services.allowanceBreakdown(
      forecast,
      { filingType: 'white' },
      taxSettings({ hasSetNationalHealthInsuranceAmount: false }),
      { businessReserveAmount: 0, otherReserveAmount: 0 }
    );

    assertEqual(breakdown.projectedProfit, -1000000);
    assertEqual(breakdown.taxResult.incomeTax.totalIncome, 0, '税計算側では0円にクランプする');
    assertTrue(breakdown.remainingAllowance < 0);
  });

  test('その他確保したい資金も差し引かれる', () => {
    const forecast = {
      year: 2026,
      revenueForecast: 6000000,
      expenseForecast: 1000000,
      isRevenueManual: true,
      isExpenseManual: true
    };
    const withoutOther = services.allowanceBreakdown(
      forecast,
      { filingType: 'blue' },
      taxSettings(),
      { businessReserveAmount: 500000, otherReserveAmount: 0 }
    );
    const withOther = services.allowanceBreakdown(
      forecast,
      { filingType: 'blue' },
      taxSettings(),
      { businessReserveAmount: 500000, otherReserveAmount: 200000 }
    );
    assertEqual(withoutOther.remainingAllowance - withOther.remainingAllowance, 200000);
  });
})(typeof globalThis !== 'undefined' ? globalThis : this);
