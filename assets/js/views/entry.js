/**
 * 売上・経費の入力シート（追加と編集の両方）。
 * 最初に見えるのは「金額」と「日付」だけにして、それ以外は「詳細を追加」で開く。
 */
(function (global) {
  'use strict';

  const c = global.Atoikura.components;
  const store = global.Atoikura.store;
  const { todayISO, escapeHTML } = global.Atoikura.format;

  /** 新規追加用の下書きを作る。 */
  function newDraft(type) {
    if (type === 'income') {
      return {
        amount: null,
        date: todayISO(),
        clientName: '',
        category: '',
        memo: '',
        isPaid: true
      };
    }
    return {
      amount: null,
      date: todayISO(),
      category: 'other',
      memo: '',
      businessRatioPercent: 100
    };
  }

  /** 既存データから下書きを作る（編集用）。 */
  function draftFrom(type, entry) {
    if (type === 'income') {
      return {
        amount: entry.amount,
        date: entry.date,
        clientName: entry.clientName || '',
        category: entry.category || '',
        memo: entry.memo || '',
        isPaid: entry.isPaid !== false
      };
    }
    return {
      amount: entry.amount,
      date: entry.date,
      category: entry.category || 'other',
      memo: entry.memo || '',
      businessRatioPercent:
        typeof entry.businessRatioPercent === 'number' ? entry.businessRatioPercent : 100
    };
  }

  /** 編集時、詳細項目に何か入っていれば最初から詳細を開いておく。 */
  function hasDetailInput(type, draft) {
    if (type === 'income') {
      return Boolean(draft.clientName || draft.category || draft.memo) || draft.isPaid === false;
    }
    return Boolean(draft.memo) || draft.businessRatioPercent !== 100;
  }

  function ratioOptions() {
    const options = [];
    for (let percent = 100; percent >= 0; percent -= 10) {
      options.push({ value: String(percent), label: percent + '%' });
    }
    return options;
  }

  function detailsSection(sheet) {
    const draft = sheet.draft;

    if (sheet.type === 'income') {
      return c.card({
        header: '詳細（任意）',
        body:
          c.textField({
            id: 'entry-client',
            label: '取引先',
            action: 'sheet-field',
            field: 'clientName',
            value: draft.clientName,
            placeholder: '株式会社○○'
          }) +
          c.textField({
            id: 'entry-category',
            label: '分類',
            action: 'sheet-field',
            field: 'category',
            value: draft.category,
            placeholder: '業務委託 など'
          }) +
          c.textField({
            id: 'entry-memo',
            label: 'メモ',
            action: 'sheet-field',
            field: 'memo',
            value: draft.memo
          }) +
          c.toggleRow({
            id: 'entry-paid',
            label: '入金済み',
            action: 'sheet-toggle',
            field: 'isPaid',
            checked: draft.isPaid
          })
      });
    }

    return c.card({
      header: '詳細（任意）',
      body:
        c.textField({
          id: 'entry-memo',
          label: 'メモ',
          action: 'sheet-field',
          field: 'memo',
          value: draft.memo
        }) +
        c.selectField({
          id: 'entry-ratio',
          label: '事業割合',
          action: 'sheet-select',
          field: 'businessRatioPercent',
          value: String(draft.businessRatioPercent),
          options: ratioOptions()
        }),
      footer: '税計算には「金額 × 事業割合」を経費として使います。'
    });
  }

  function render(sheet) {
    const draft = sheet.draft;
    const isEditing = Boolean(sheet.id);
    const title =
      (sheet.type === 'income' ? '売上' : '経費') + (isEditing ? 'を編集' : 'を追加');

    const amountBlock = c.card({
      body: c.amountField({
        id: 'entry-amount',
        label: '金額',
        action: 'sheet-amount',
        value: draft.amount
      })
    });

    const dateBlock = c.card({
      body: c.textField({
        id: 'entry-date',
        label: '日付',
        type: 'date',
        action: 'sheet-field',
        field: 'date',
        value: draft.date
      })
    });

    const categoryBlock =
      sheet.type === 'expense'
        ? c.card({
            body: c.selectField({
              id: 'entry-expense-category',
              label: 'カテゴリー',
              action: 'sheet-select',
              field: 'category',
              value: draft.category,
              options: store.EXPENSE_CATEGORIES.map(function (item) {
                return { value: item.id, label: item.name };
              })
            })
          })
        : '';

    const details = sheet.showDetails
      ? detailsSection(sheet)
      : '<button type="button" class="btn btn-block btn-quiet" data-action="toggle-sheet-details">' +
        '＋ 詳細を追加</button>';

    const deleteButton = isEditing
      ? '<button type="button" class="btn btn-block btn-danger" data-action="sheet-delete" ' +
        'style="margin-top:16px">この記録を削除</button>'
      : '';

    const canSave = typeof draft.amount === 'number' && draft.amount > 0;

    return (
      '<div class="sheet-backdrop" data-action="sheet-backdrop">' +
      '<div class="sheet" role="dialog" aria-modal="true" aria-label="' + escapeHTML(title) + '">' +
      '<div class="sheet-header">' +
      '<button type="button" data-action="sheet-cancel">キャンセル</button>' +
      '<h2>' + escapeHTML(title) + '</h2>' +
      '<button type="button" class="save" data-action="sheet-save" id="sheet-save"' +
      (canSave ? '' : ' disabled') + '>保存</button>' +
      '</div>' +
      '<div class="sheet-body">' +
      amountBlock +
      dateBlock +
      categoryBlock +
      details +
      deleteButton +
      '</div>' +
      '</div>' +
      '</div>'
    );
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.views = global.Atoikura.views || {};
  global.Atoikura.views.entry = { render, newDraft, draftFrom, hasDetailInput };
})(typeof globalThis !== 'undefined' ? globalThis : this);
