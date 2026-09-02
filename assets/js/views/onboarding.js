/**
 * 初回起動時のオンボーディング（最大4画面）。
 * 入力項目を増やしすぎず、最短でホーム画面まで到達させることを優先する。
 * どの画面からでも「あとで設定する」でホームへ進める。
 */
(function (global) {
  'use strict';

  const c = global.Atoikura.components;
  const store = global.Atoikura.store;
  const { escapeHTML } = global.Atoikura.format;

  const TOTAL_STEPS = 4;

  function newDraft() {
    const year = store.currentYear();
    return {
      step: 0,
      displayName: '',
      businessStartYear: year,
      filingType: 'blue',
      revenue: null,
      expense: null,
      reserve: null
    };
  }

  function yearOptions(from, to) {
    const options = [];
    for (let year = to; year >= from; year -= 1) {
      options.push({ value: String(year), label: year + '年' });
    }
    return options;
  }

  function progress(step) {
    let html = '<div class="progress" aria-label="全' + TOTAL_STEPS + '画面中 ' + (step + 1) + '画面目">';
    for (let i = 0; i < TOTAL_STEPS; i += 1) {
      html += '<span class="' + (i <= step ? 'is-done' : '') + '"></span>';
    }
    return html + '</div>';
  }

  function choiceButton(options) {
    return (
      '<button type="button" class="choice" data-action="onboarding-choice" ' +
      'data-field="filingType" data-value="' + escapeHTML(options.value) + '" ' +
      'aria-pressed="' + (options.selected ? 'true' : 'false') + '">' +
      '<span>' +
      '<span class="choice-title">' + escapeHTML(options.title) + '</span><br>' +
      '<span class="choice-desc">' + escapeHTML(options.description) + '</span>' +
      '</span>' +
      '<span class="check" aria-hidden="true">✓</span>' +
      '</button>'
    );
  }

  function stepBody(draft) {
    const thisYear = store.currentYear();

    switch (draft.step) {
      case 0:
        return (
          '<h1>あといくらへようこそ</h1>' +
          '<p class="lead">売上・経費・税金をもとに、今年あと使えるお金を把握できるようにします。</p>' +
          c.card({
            body:
              c.textField({
                id: 'onboarding-name',
                label: '表示名（任意）',
                action: 'onboarding-field',
                field: 'displayName',
                value: draft.displayName,
                placeholder: '屋号やお名前'
              }) +
              c.selectField({
                id: 'onboarding-start-year',
                label: '事業開始年',
                action: 'onboarding-select',
                field: 'businessStartYear',
                value: String(draft.businessStartYear),
                options: yearOptions(thisYear - 30, thisYear)
              })
          })
        );

      case 1:
        return (
          '<h1>申告方法を教えてください</h1>' +
          '<p class="lead">あとから設定画面で変更できます。わからない場合は「白色申告」で大丈夫です。</p>' +
          c.card({
            body:
              choiceButton({
                value: 'blue',
                title: '青色申告',
                description: '複式簿記などの要件を満たすと控除が受けられます',
                selected: draft.filingType === 'blue'
              }) +
              choiceButton({
                value: 'white',
                title: '白色申告',
                description: '比較的シンプルな帳簿づけで申告できます',
                selected: draft.filingType === 'white'
              })
          })
        );

      case 2:
        return (
          '<h1>今年の見込みを教えてください</h1>' +
          '<p class="lead">わかる範囲で大丈夫です。あとから変更できますし、売上・経費を登録すると自動でも計算されます。</p>' +
          c.card({
            body:
              c.amountField({
                id: 'onboarding-revenue',
                label: '年間売上見込み（任意）',
                action: 'onboarding-amount',
                field: 'revenue',
                value: draft.revenue
              }) +
              c.amountField({
                id: 'onboarding-expense',
                label: '年間経費見込み（任意）',
                action: 'onboarding-amount',
                field: 'expense',
                value: draft.expense
              })
          }) +
          c.card({
            body: c.amountField({
              id: 'onboarding-reserve',
              label: '事業用に残しておきたい予備資金',
              action: 'onboarding-amount',
              field: 'reserve',
              value: draft.reserve
            }),
            footer: '急な出費や税金の支払いに備えて確保しておきたい金額の目安です。'
          })
        );

      default:
        return (
          '<h1>準備ができました</h1>' +
          '<p class="lead">今年あと使えるお金を見てみましょう。</p>' +
          c.card({ body: '<div class="field">' + c.disclaimerText() + '</div>' })
        );
    }
  }

  function render(draft) {
    const isLast = draft.step === TOTAL_STEPS - 1;

    const actions =
      '<div class="onboarding-actions">' +
      (draft.step > 0
        ? '<button type="button" class="btn btn-quiet" data-action="onboarding-back">戻る</button>'
        : '') +
      '<span class="spacer" style="flex:1"></span>' +
      (isLast
        ? '<button type="button" class="btn btn-primary" data-action="onboarding-finish">' +
          '今年あと使えるお金を見る</button>'
        : '<button type="button" class="btn btn-quiet" data-action="onboarding-finish">あとで設定する</button>' +
          '<button type="button" class="btn btn-primary" data-action="onboarding-next">次へ</button>') +
      '</div>';

    return (
      '<div class="onboarding">' +
      progress(draft.step) +
      '<div class="onboarding-body">' +
      stepBody(draft) +
      '</div>' +
      actions +
      '</div>'
    );
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.views = global.Atoikura.views || {};
  global.Atoikura.views.onboarding = { render, newDraft, TOTAL_STEPS };
})(typeof globalThis !== 'undefined' ? globalThis : this);
