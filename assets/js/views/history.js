/**
 * 履歴画面。売上・経費を月別にまとめて表示する。
 * 日付は 'YYYY-MM-DD' の文字列なので、月のグループ化も文字列の切り出しで行う
 * （タイムゾーンによって表示月がずれる不具合が起きない）。
 */
(function (global) {
  'use strict';

  const c = global.Atoikura.components;
  const store = global.Atoikura.store;
  const { currency, escapeHTML, shortDate, monthLabel } = global.Atoikura.format;

  /** 売上・経費を同じ一覧に並べるための表示用オブジェクトへ変換する。 */
  function toItems(ctx, segment) {
    const items = [];

    if (segment !== 'expense') {
      ctx.state.incomes.forEach(function (t) {
        items.push({
          kind: 'income',
          id: t.id,
          date: t.date,
          title: t.clientName ? t.clientName : '売上',
          meta: t.category || '',
          amount: t.amount,
          unpaid: t.isPaid === false
        });
      });
    }

    if (segment !== 'income') {
      ctx.state.expenses.forEach(function (t) {
        items.push({
          kind: 'expense',
          id: t.id,
          date: t.date,
          title: store.expenseCategoryName(t.category),
          meta: t.businessRatioPercent !== 100 ? '事業割合 ' + t.businessRatioPercent + '%' : '',
          amount: t.amount,
          unpaid: false
        });
      });
    }

    return items.sort(function (a, b) {
      if (a.date === b.date) return 0;
      return a.date < b.date ? 1 : -1;
    });
  }

  function groupByMonth(items) {
    const groups = [];
    const index = {};

    items.forEach(function (item) {
      const key = String(item.date).slice(0, 7);
      if (!index[key]) {
        index[key] = { key, items: [] };
        groups.push(index[key]);
      }
      index[key].items.push(item);
    });

    return groups;
  }

  function entryRow(item) {
    const amountText = (item.kind === 'income' ? '+' : '-') + currency(Math.abs(item.amount)).replace('-', '');
    const meta = [shortDate(item.date), item.meta].filter(Boolean).join(' · ');
    const badge = item.unpaid ? '<span class="badge">未入金</span>' : '';

    return (
      '<button type="button" class="entry-row" ' +
      'data-action="' + (item.kind === 'income' ? 'edit-income' : 'edit-expense') + '" ' +
      'data-id="' + escapeHTML(item.id) + '">' +
      '<span class="entry-main">' +
      '<span class="entry-title">' + escapeHTML(item.title) + badge + '</span>' +
      '<span class="entry-meta">' + escapeHTML(meta) + '</span>' +
      '</span>' +
      '<span class="entry-amount' + (item.kind === 'expense' ? ' is-expense' : '') + '">' +
      escapeHTML(amountText) +
      '</span>' +
      '</button>'
    );
  }

  function render(ctx) {
    const segment = global.Atoikura.app.uiState.historySegment;

    const segmentedControl = c.segmented({
      action: 'set-history-segment',
      value: segment,
      items: [
        { value: 'all', label: 'すべて' },
        { value: 'income', label: '売上' },
        { value: 'expense', label: '経費' }
      ]
    });

    const actions =
      '<div class="actions-grid">' +
      '<button type="button" class="btn btn-primary" data-action="add-income">売上を追加</button>' +
      '<button type="button" class="btn" data-action="add-expense">経費を追加</button>' +
      '</div>';

    const items = toItems(ctx, segment);

    if (items.length === 0) {
      return (
        '<h2 class="screen-title">履歴</h2>' +
        segmentedControl +
        actions +
        c.emptyState({
          icon: '🧾',
          title: 'まだ記録がありません',
          description: '上のボタンから売上・経費を追加できます'
        })
      );
    }

    const groups = groupByMonth(items)
      .map(function (group) {
        return (
          '<div class="month-group">' +
          '<h3>' + escapeHTML(monthLabel(group.key)) + '</h3>' +
          '<section class="card">' +
          group.items.map(entryRow).join('') +
          '</section>' +
          '</div>'
        );
      })
      .join('');

    return (
      '<h2 class="screen-title">履歴</h2>' +
      segmentedControl +
      actions +
      groups +
      '<p class="disclaimer">項目をタップすると編集・削除できます。</p>'
    );
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.views = global.Atoikura.views || {};
  global.Atoikura.views.history = { render, toItems, groupByMonth };
})(typeof globalThis !== 'undefined' ? globalThis : this);
