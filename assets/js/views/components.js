/**
 * 画面を組み立てるための小さな共通パーツ。
 * すべて「HTML文字列を返すだけ」の関数にして、状態は持たせない。
 */
(function (global) {
  'use strict';

  const { escapeHTML, currency } = global.Atoikura.format;

  function card(options) {
    const header = options.header
      ? '<div class="card-header">' + escapeHTML(options.header) + '</div>'
      : '';
    const footer = options.footer
      ? '<div class="card-footer">' + escapeHTML(options.footer) + '</div>'
      : '';
    return '<section class="card">' + header + options.body + footer + '</section>';
  }

  /** ラベルと金額（または任意の値）を左右に並べる行。 */
  function row(label, value, options) {
    const opts = options || {};
    const classNames = ['row'];
    if (opts.emphasized) classNames.push('is-emphasized');
    const sub = opts.sub ? '<span class="row-sub">' + escapeHTML(opts.sub) + '</span>' : '';
    // live を指定すると、入力中の部分更新（app.updateLiveValues）の対象になる
    const live = opts.live ? ' data-live="' + escapeHTML(opts.live) + '"' : '';
    return (
      '<div class="' + classNames.join(' ') + '">' +
      '<div class="row-label">' + escapeHTML(label) + sub + '</div>' +
      '<div class="row-value"' + live + '>' + escapeHTML(value) + '</div>' +
      '</div>'
    );
  }

  function amountRow(label, amount, options) {
    return row(label, currency(amount), options);
  }

  /**
   * 金額入力欄。数字だけを受け付け、下に「¥1,000,000」の形式でプレビューを出す。
   * 入力中にカンマを挿し込むとカーソル位置がずれるため、確定表示は別行に分けている。
   */
  function amountField(options) {
    const value = options.value === null || options.value === undefined ? '' : String(options.value);
    const preview = value === '' ? '' : currency(Number(value));
    return (
      '<div class="field">' +
      (options.label ? '<label for="' + escapeHTML(options.id) + '">' + escapeHTML(options.label) + '</label>' : '') +
      '<div class="amount-field">' +
      '<span class="currency-mark" aria-hidden="true">¥</span>' +
      '<input type="text" inputmode="numeric" autocomplete="off" ' +
      'id="' + escapeHTML(options.id) + '" ' +
      'data-action="' + escapeHTML(options.action) + '" ' +
      (options.field ? 'data-field="' + escapeHTML(options.field) + '" ' : '') +
      'placeholder="' + escapeHTML(options.placeholder || '0') + '" ' +
      'value="' + escapeHTML(value) + '">' +
      '</div>' +
      '<div class="amount-preview" data-preview-for="' + escapeHTML(options.id) + '">' +
      escapeHTML(preview) +
      '</div>' +
      '</div>'
    );
  }

  function textField(options) {
    return (
      '<div class="field">' +
      '<label for="' + escapeHTML(options.id) + '">' + escapeHTML(options.label) + '</label>' +
      '<input type="' + escapeHTML(options.type || 'text') + '" ' +
      'id="' + escapeHTML(options.id) + '" ' +
      'data-action="' + escapeHTML(options.action) + '" ' +
      (options.field ? 'data-field="' + escapeHTML(options.field) + '" ' : '') +
      'placeholder="' + escapeHTML(options.placeholder || '') + '" ' +
      'value="' + escapeHTML(options.value == null ? '' : options.value) + '">' +
      '</div>'
    );
  }

  /** options: [{value, label}] */
  function selectField(options) {
    const items = options.options
      .map(function (item) {
        const selected = String(item.value) === String(options.value) ? ' selected' : '';
        return (
          '<option value="' + escapeHTML(item.value) + '"' + selected + '>' +
          escapeHTML(item.label) +
          '</option>'
        );
      })
      .join('');

    return (
      '<div class="field">' +
      '<label for="' + escapeHTML(options.id) + '">' + escapeHTML(options.label) + '</label>' +
      '<select id="' + escapeHTML(options.id) + '" ' +
      'data-action="' + escapeHTML(options.action) + '" ' +
      (options.field ? 'data-field="' + escapeHTML(options.field) + '" ' : '') +
      '>' + items + '</select>' +
      '</div>'
    );
  }

  function toggleRow(options) {
    return (
      '<div class="toggle-row">' +
      '<label for="' + escapeHTML(options.id) + '">' + escapeHTML(options.label) + '</label>' +
      '<input type="checkbox" id="' + escapeHTML(options.id) + '" ' +
      'data-action="' + escapeHTML(options.action) + '" ' +
      (options.field ? 'data-field="' + escapeHTML(options.field) + '" ' : '') +
      (options.checked ? 'checked' : '') +
      '>' +
      '</div>'
    );
  }

  function stepperRow(options) {
    return (
      '<div class="row">' +
      '<div class="row-label">' + escapeHTML(options.label) + '</div>' +
      '<div class="stepper">' +
      '<button type="button" data-action="' + escapeHTML(options.action) + '" data-delta="-1" ' +
      'aria-label="' + escapeHTML(options.label) + 'を減らす">−</button>' +
      '<span class="stepper-value">' + escapeHTML(options.display) + '</span>' +
      '<button type="button" data-action="' + escapeHTML(options.action) + '" data-delta="1" ' +
      'aria-label="' + escapeHTML(options.label) + 'を増やす">＋</button>' +
      '</div>' +
      '</div>'
    );
  }

  function segmented(options) {
    const buttons = options.items
      .map(function (item) {
        const selected = item.value === options.value;
        return (
          '<button type="button" role="tab" aria-selected="' + (selected ? 'true' : 'false') + '" ' +
          'data-action="' + escapeHTML(options.action) + '" ' +
          'data-value="' + escapeHTML(item.value) + '">' +
          escapeHTML(item.label) +
          '</button>'
        );
      })
      .join('');
    return '<div class="segmented" role="tablist">' + buttons + '</div>';
  }

  function emptyState(options) {
    return (
      '<div class="empty-state">' +
      '<div class="empty-icon" aria-hidden="true">' + escapeHTML(options.icon || '📄') + '</div>' +
      '<p><strong>' + escapeHTML(options.title) + '</strong></p>' +
      (options.description ? '<p>' + escapeHTML(options.description) + '</p>' : '') +
      '</div>'
    );
  }

  function disclaimerText() {
    return (
      '<p class="disclaimer">表示される税額・社会保険料はあくまで概算です。実際の金額を保証するものではありません。' +
      '確定申告や税務上の判断については、税務署や税理士にご確認ください。</p>'
    );
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.components = {
    card,
    row,
    amountRow,
    amountField,
    textField,
    selectField,
    toggleRow,
    stepperRow,
    segmented,
    emptyState,
    disclaimerText
  };
})(typeof globalThis !== 'undefined' ? globalThis : this);
