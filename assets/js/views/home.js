/**
 * ホーム画面。「今年あと使えるお金」を主役に据える。
 * 情報をカードだらけにせず、重要度で視覚的な強弱をつける。
 */
(function (global) {
  'use strict';

  const c = global.Atoikura.components;
  const { currency, escapeHTML } = global.Atoikura.format;

  function statusChip(breakdown) {
    if (breakdown.remainingAllowance < 0) {
      return '<span class="status is-negative">⚠ 予定より不足しています</span>';
    }
    return '<span class="status">✓ 使える見込みの金額です</span>';
  }

  function forecastNote(breakdown, ctx) {
    if (ctx.forecast.isRevenueManual && ctx.forecast.isExpenseManual) return '手動で設定した予測';
    if (ctx.forecast.isRevenueManual || ctx.forecast.isExpenseManual) return '一部を手動で設定';
    return '実績からの自動予測';
  }

  function notices(ctx) {
    const items = [];

    if (!ctx.tax.hasSetNationalHealthInsuranceAmount) {
      items.push(
        '<div class="notice is-warning">国民健康保険料が未設定のため0円で計算しています。' +
          '設定タブで年額を入れると精度が上がります。</div>'
      );
    }

    if (!global.Atoikura.store.isStorageAvailable()) {
      items.push(
        '<div class="notice is-warning">この環境ではデータを保存できません（ブラウザの設定をご確認ください）。' +
          '入力内容はページを閉じると消えます。</div>'
      );
    }

    return items.join('');
  }

  /**
   * 計算の土台になる売上の情報があるか。
   * 何も登録していない状態では、予備資金や国民年金だけが差し引かれて
   * 大きなマイナスが出てしまい、初めて開いた人を驚かせてしまうため、
   * その場合は金額ではなく案内を表示する。
   */
  function hasBasisForForecast(ctx) {
    return (
      ctx.forecast.isRevenueManual ||
      ctx.forecast.revenueForecast > 0 ||
      ctx.state.incomes.length > 0
    );
  }

  function render(ctx) {
    const b = ctx.breakdown;
    const isNegative = b.remainingAllowance < 0;
    const hasBasis = hasBasisForForecast(ctx);

    const hero = hasBasis
      ? '<div class="hero">' +
        '<div class="label">今年あと使えるお金</div>' +
        '<div class="amount' + (isNegative ? ' is-negative' : '') + '">' +
        escapeHTML(currency(b.remainingAllowance)) +
        '</div>' +
        '<div class="note">現在の入力内容から算出した概算です</div>' +
        statusChip(b) +
        '</div>'
      : '<div class="hero">' +
        '<div class="label">今年あと使えるお金</div>' +
        '<div class="amount">—</div>' +
        '<div class="note">売上を登録するか、予測タブで年間の見込みを入力すると計算できます</div>' +
        '</div>';

    const quickActions =
      '<div class="actions-grid">' +
      '<button type="button" class="btn btn-primary" data-action="add-income">売上を追加</button>' +
      '<button type="button" class="btn" data-action="add-expense">経費を追加</button>' +
      '</div>';

    const breakdownOpen = global.Atoikura.app.uiState.homeBreakdownOpen;
    const breakdownBody =
      '<button type="button" class="disclosure-button" data-action="toggle-home-breakdown" ' +
      'aria-expanded="' + (breakdownOpen ? 'true' : 'false') + '">' +
      '<span>内訳を見る</span><span aria-hidden="true">' + (breakdownOpen ? '▲' : '▼') + '</span>' +
      '</button>' +
      (breakdownOpen
        ? c.amountRow('今年の売上', b.revenueForecast, { sub: forecastNote(b, ctx) }) +
          c.amountRow('今年の経費', b.expenseForecast) +
          c.amountRow('予想利益', b.projectedProfit, { emphasized: true }) +
          c.amountRow('税金・社会保険として確保', b.taxAndSocialInsurance) +
          c.amountRow('事業用に残すお金', b.businessReserve + b.otherReserve)
        : '');

    const breakdownCard =
      '<section class="card">' +
      breakdownBody +
      (breakdownOpen
        ? '<div class="card-footer">税金・社会保険は概算です。内訳や前提は設定タブで調整できます。</div>'
        : '') +
      '</section>';

    const emptyHint =
      ctx.state.incomes.length === 0 && ctx.state.expenses.length === 0
        ? '<p class="disclaimer">売上や経費を登録すると、実績にもとづいて数字が更新されます。</p>'
        : '';

    // 一番大事な数字を最初に見せたいので、お知らせは金額のあとに置く
    return hero + quickActions + notices(ctx) + breakdownCard + emptyHint;
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.views = global.Atoikura.views || {};
  global.Atoikura.views.home = { render };
})(typeof globalThis !== 'undefined' ? globalThis : this);
