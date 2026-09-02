/**
 * 年間集計 → 年間予測 → 「今年あと使えるお金」の組み立て。
 * DOM に依存しない純粋な計算だけを置く（テスト可能にするため）。
 *
 * 日付は 'YYYY-MM-DD' の文字列で扱い、年・月の判定は文字列の前方一致で行う。
 * Date オブジェクトとタイムゾーンを介さないので、端末のタイムゾーン設定によって
 * 集計対象の月がずれる類の不具合が原理的に起きない。
 */
(function (global) {
  'use strict';

  /** 経費のうち実際に経費として扱う金額（金額 × 事業割合）。 */
  function deductibleExpenseAmount(expense) {
    const ratio = typeof expense.businessRatioPercent === 'number'
      ? expense.businessRatioPercent
      : 100;
    return Math.floor((expense.amount * ratio) / 100);
  }

  /**
   * 指定年度の売上・経費の実績を集計する。
   * @param {number} year 対象年度
   * @param {Array} incomes 売上の配列
   * @param {Array} expenses 経費の配列
   * @param {string} todayISO 今日の日付 'YYYY-MM-DD'
   */
  function annualActuals(year, incomes, expenses, todayISO) {
    const prefix = String(year) + '-';
    const yearIncomes = incomes.filter((t) => String(t.date).startsWith(prefix));
    const yearExpenses = expenses.filter((t) => String(t.date).startsWith(prefix));

    const totalRevenue = yearIncomes.reduce((sum, t) => sum + t.amount, 0);
    const totalExpense = yearExpenses.reduce((sum, t) => sum + deductibleExpenseAmount(t), 0);

    const currentYear = Number(todayISO.slice(0, 4));
    const currentMonth = Number(todayISO.slice(5, 7));
    let elapsedMonths;
    if (year < currentYear) {
      elapsedMonths = 12;
    } else if (year > currentYear) {
      elapsedMonths = 0;
    } else {
      elapsedMonths = currentMonth;
    }

    return { year, totalRevenue, totalExpense, elapsedMonths };
  }

  /** 実績を1年分へ単純に年間換算する（実績 ÷ 経過月数 × 12）。 */
  function projectedAnnualAmount(actual, elapsedMonths) {
    if (!(elapsedMonths > 0)) return actual;
    const months = Math.min(elapsedMonths, 12);
    return Math.round((actual / months) * 12);
  }

  /**
   * 年間予測。手動設定値があればそれを優先し、無ければ実績ベースの自動予測を使う。
   * 自動予測なのか手動設定なのかを結果に持たせて、UI で区別できるようにする。
   */
  function annualForecast(actuals, manualRevenueForecast, manualExpenseForecast) {
    const isRevenueManual =
      manualRevenueForecast !== null && manualRevenueForecast !== undefined;
    const isExpenseManual =
      manualExpenseForecast !== null && manualExpenseForecast !== undefined;

    return {
      year: actuals.year,
      revenueForecast: isRevenueManual
        ? manualRevenueForecast
        : projectedAnnualAmount(actuals.totalRevenue, actuals.elapsedMonths),
      expenseForecast: isExpenseManual
        ? manualExpenseForecast
        : projectedAnnualAmount(actuals.totalExpense, actuals.elapsedMonths),
      isRevenueManual,
      isExpenseManual
    };
  }

  /**
   * 「今年あと使えるお金」の内訳を組み立てる。
   *
   * 会計上の利益と現金の動きを混同しないよう、Ver1.0 では
   * 「年間の予想利益をベースにした、あと使えるお金」という単一の考え方に絞っている
   * （入金済み / 未入金の区別は履歴の表示にのみ使い、この計算には使わない）。
   */
  function allowanceBreakdown(forecast, profile, taxSettings, reserveSettings) {
    const projectedProfit = forecast.revenueForecast - forecast.expenseForecast;

    const taxResult = global.Atoikura.tax.calculate({
      year: forecast.year,
      businessProfit: Math.max(0, projectedProfit),
      filingType: profile.filingType,
      blueReturnDeduction: taxSettings.blueReturnDeduction,
      dependentsCount: taxSettings.dependentsCount,
      hasSpouse: taxSettings.hasSpouse,
      isNationalPensionEnrolled: taxSettings.isNationalPensionEnrolled,
      nationalHealthInsuranceAnnualAmount: taxSettings.nationalHealthInsuranceAnnualAmount,
      hasSetNationalHealthInsuranceAmount: taxSettings.hasSetNationalHealthInsuranceAmount,
      businessTaxCategory: taxSettings.businessTaxCategory
    });

    const businessReserve = reserveSettings.businessReserveAmount || 0;
    const otherReserve = reserveSettings.otherReserveAmount || 0;

    return {
      year: forecast.year,
      revenueForecast: forecast.revenueForecast,
      expenseForecast: forecast.expenseForecast,
      projectedProfit,
      taxAndSocialInsurance: taxResult.total,
      businessReserve,
      otherReserve,
      // 赤字の場合はマイナスのまま返す（税計算のクランプに引きずられないようにする）
      remainingAllowance: projectedProfit - taxResult.total - businessReserve - otherReserve,
      taxResult
    };
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.services = {
    deductibleExpenseAmount,
    annualActuals,
    projectedAnnualAmount,
    annualForecast,
    allowanceBreakdown
  };
})(typeof globalThis !== 'undefined' ? globalThis : this);
