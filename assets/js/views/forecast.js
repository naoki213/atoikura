/**
 * 予測画面。実績ベースの自動予測と、手動で決めた予測を切り替えられるようにする。
 * どちらが使われているかを必ず画面上で区別できるようにする。
 */
(function (global) {
  'use strict';

  const c = global.Atoikura.components;
  const { currency } = global.Atoikura.format;

  function section(options) {
    const manualField = options.isManual
      ? c.amountField({
          id: options.id,
          label: '手動で設定する金額',
          action: 'forecast-amount',
          field: options.field,
          value: options.manualValue
        })
      : c.row('自動予測', currency(options.autoValue), {
          sub: '今年の実績 ' + currency(options.actual) + ' を年間換算'
        });

    return c.card({
      header: options.header,
      body:
        c.toggleRow({
          id: options.id + '-toggle',
          label: '手動で設定する',
          action: 'forecast-toggle',
          field: options.field,
          checked: options.isManual
        }) + manualField
    });
  }

  function render(ctx) {
    const tax = ctx.tax;
    const autoForecast = global.Atoikura.services.annualForecast(ctx.actuals, null, null);

    const intro =
      '<div class="notice">今年の実績（' +
      ctx.actuals.elapsedMonths +
      'か月分）をもとに1年分を自動で見積もっています。実態と違う場合は手動で設定できます。</div>';

    const revenueSection = section({
      header: '今年の売上予測',
      id: 'forecast-revenue',
      field: 'manualRevenueForecast',
      isManual: ctx.forecast.isRevenueManual,
      manualValue: tax.manualRevenueForecast,
      autoValue: autoForecast.revenueForecast,
      actual: ctx.actuals.totalRevenue
    });

    const expenseSection = section({
      header: '今年の経費予測',
      id: 'forecast-expense',
      field: 'manualExpenseForecast',
      isManual: ctx.forecast.isExpenseManual,
      manualValue: tax.manualExpenseForecast,
      autoValue: autoForecast.expenseForecast,
      actual: ctx.actuals.totalExpense
    });

    const profitCard = c.card({
      header: '予想利益',
      body:
        c.amountRow('売上予測', ctx.forecast.revenueForecast, { live: 'revenue-forecast' }) +
        c.amountRow('経費予測', ctx.forecast.expenseForecast, { live: 'expense-forecast' }) +
        c.amountRow('予想利益', ctx.breakdown.projectedProfit, {
          emphasized: true,
          live: 'projected-profit'
        })
    });

    return (
      '<h2 class="screen-title">予測</h2>' + intro + revenueSection + expenseSection + profitCard
    );
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.views = global.Atoikura.views || {};
  global.Atoikura.views.forecast = { render };
})(typeof globalThis !== 'undefined' ? globalThis : this);
