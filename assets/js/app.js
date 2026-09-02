/**
 * 画面の組み立てと操作の受け口。
 *
 * 方針:
 * - 計算は tax / services に、保存は store に任せ、ここは「つなぐ」だけにする。
 * - 操作は data-action 属性で宣言し、イベント委譲でまとめて受ける
 *   （再描画のたびにイベントを貼り直さなくてよいので、リスナーの取り残しが起きない）。
 * - 文字入力中は再描画しない（入力欄が作り直されてカーソルが飛ぶのを防ぐため）。
 *   金額のプレビューや連動する数字は data-live の要素だけを部分更新する。
 */
(function (global) {
  'use strict';

  const store = global.Atoikura.store;
  const services = global.Atoikura.services;
  const views = global.Atoikura.views;
  const format = global.Atoikura.format;

  /**
   * タブのアイコン。絵文字だと家計簿アプリのように見えてしまうため、
   * 線だけの単色アイコン（currentColor）を使って落ち着いた印象にする。
   */
  function icon(paths) {
    return (
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" ' +
      'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
      paths +
      '</svg>'
    );
  }

  const TABS = [
    {
      id: 'home',
      label: 'ホーム',
      icon: icon('<path d="M3 10.5 12 4l9 6.5V19a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>')
    },
    {
      id: 'history',
      label: '履歴',
      icon: icon('<path d="M4 6.5h16"/><path d="M4 12h16"/><path d="M4 17.5h10"/>')
    },
    {
      id: 'forecast',
      label: '予測',
      icon: icon('<path d="M4 16.5l5-5 3.5 3.5L20 7.5"/><path d="M15.5 7.5H20v4.5"/>')
    },
    {
      id: 'settings',
      label: '設定',
      icon: icon(
        '<path d="M4 8h8"/><path d="M17 8h3"/><path d="M4 16h4"/><path d="M13 16h7"/>' +
          '<circle cx="14.5" cy="8" r="2.2"/><circle cx="10.5" cy="16" r="2.2"/>'
      )
    }
  ];

  const uiState = {
    activeTab: 'home',
    historySegment: 'all',
    homeBreakdownOpen: true,
    sheet: null,
    onboarding: null
  };

  /** 画面が必要とする値を一式そろえる。 */
  function context() {
    const state = store.getState();
    const year = state.appSettings.selectedYear;
    const tax = store.taxSettingsFor(year);
    const actuals = services.annualActuals(year, state.incomes, state.expenses, format.todayISO());
    const forecast = services.annualForecast(
      actuals,
      tax.manualRevenueForecast,
      tax.manualExpenseForecast
    );
    const breakdown = services.allowanceBreakdown(forecast, state.profile, tax, state.reserve);
    return { state, year, tax, actuals, forecast, breakdown };
  }

  function root() {
    return document.getElementById('root');
  }

  function renderTabbar() {
    const buttons = TABS.map(function (tab) {
      return (
        '<button type="button" role="tab" data-action="nav-tab" data-tab="' + tab.id + '" ' +
        'aria-selected="' + (uiState.activeTab === tab.id ? 'true' : 'false') + '">' +
        '<span class="tab-icon" aria-hidden="true">' + tab.icon + '</span>' +
        '<span>' + tab.label + '</span>' +
        '</button>'
      );
    }).join('');

    return '<nav class="tabbar" role="tablist"><div class="tabbar-inner">' + buttons + '</div></nav>';
  }

  function renderMain(ctx) {
    switch (uiState.activeTab) {
      case 'history':
        return views.history.render(ctx);
      case 'forecast':
        return views.forecast.render(ctx);
      case 'settings':
        return views.settings.render(ctx);
      default:
        return views.home.render(ctx);
    }
  }

  function render() {
    const state = store.getState();

    if (!state.appSettings.hasCompletedOnboarding) {
      if (!uiState.onboarding) uiState.onboarding = views.onboarding.newDraft();
      root().innerHTML = views.onboarding.render(uiState.onboarding);
      return;
    }

    const ctx = context();
    const displayName = state.profile.displayName;

    root().innerHTML =
      '<div class="app">' +
      '<header class="app-header">' +
      '<span class="year">' + ctx.year + '年</span>' +
      '<span class="app-name">' +
      (displayName ? format.escapeHTML(displayName) : 'あといくら') +
      '</span>' +
      '</header>' +
      '<main>' + renderMain(ctx) + '</main>' +
      renderTabbar() +
      '</div>' +
      (uiState.sheet ? views.entry.render(uiState.sheet) : '');
  }

  /** 入力中に再描画せず、連動する数字だけを差し替える。 */
  function updateLiveValues() {
    const state = store.getState();
    if (!state.appSettings.hasCompletedOnboarding) return;

    const ctx = context();
    const values = {
      'tax-total': format.currency(ctx.breakdown.taxAndSocialInsurance),
      'revenue-forecast': format.currency(ctx.forecast.revenueForecast),
      'expense-forecast': format.currency(ctx.forecast.expenseForecast),
      'projected-profit': format.currency(ctx.breakdown.projectedProfit)
    };

    Object.keys(values).forEach(function (key) {
      document.querySelectorAll('[data-live="' + key + '"]').forEach(function (element) {
        element.textContent = values[key];
      });
    });
  }

  /** 保存に失敗したときだけ知らせる（黙って消えるのが一番困るため）。 */
  function saved(ok) {
    if (!ok) {
      global.alert('保存できませんでした。ブラウザの設定（プライベートモードなど）をご確認ください。');
    }
    return ok;
  }

  // --- 金額入力の共通処理 --------------------------------------------------

  function readAmountInput(element) {
    const digits = element.value.replace(/[^0-9]/g, '');
    if (digits !== element.value) element.value = digits;
    const value = digits === '' ? null : Number(digits);

    const preview = document.querySelector('[data-preview-for="' + element.id + '"]');
    if (preview) preview.textContent = value === null ? '' : format.currency(value);

    return value;
  }

  // --- 入力シート ----------------------------------------------------------

  function openSheet(type, id) {
    const state = store.getState();
    let draft;

    if (id) {
      const list = type === 'income' ? state.incomes : state.expenses;
      const entry = list.find(function (t) {
        return t.id === id;
      });
      if (!entry) return;
      draft = views.entry.draftFrom(type, entry);
    } else {
      draft = views.entry.newDraft(type);
    }

    uiState.sheet = {
      type,
      id: id || null,
      draft,
      showDetails: id ? views.entry.hasDetailInput(type, draft) : false
    };
    render();
  }

  function closeSheet() {
    uiState.sheet = null;
    render();
  }

  function saveSheet() {
    const sheet = uiState.sheet;
    if (!sheet) return;

    const draft = sheet.draft;
    if (!(typeof draft.amount === 'number' && draft.amount > 0)) return;
    if (!draft.date) draft.date = format.todayISO();

    let ok;
    if (sheet.type === 'income') {
      const payload = {
        amount: draft.amount,
        date: draft.date,
        clientName: draft.clientName,
        category: draft.category,
        memo: draft.memo,
        isPaid: draft.isPaid
      };
      ok = sheet.id ? store.updateIncome(sheet.id, payload) : store.addIncome(payload);
    } else {
      const payload = {
        amount: draft.amount,
        date: draft.date,
        category: draft.category,
        memo: draft.memo,
        businessRatioPercent: Number(draft.businessRatioPercent)
      };
      ok = sheet.id ? store.updateExpense(sheet.id, payload) : store.addExpense(payload);
    }

    if (saved(ok)) closeSheet();
  }

  function deleteSheetEntry() {
    const sheet = uiState.sheet;
    if (!sheet || !sheet.id) return;
    if (!global.confirm('この記録を削除しますか？この操作は取り消せません。')) return;

    const ok = sheet.type === 'income' ? store.deleteIncome(sheet.id) : store.deleteExpense(sheet.id);
    if (saved(ok)) closeSheet();
  }

  // --- オンボーディング ----------------------------------------------------

  function finishOnboarding() {
    const draft = uiState.onboarding || views.onboarding.newDraft();
    const year = store.currentYear();

    const ok = store.update(function (state) {
      state.profile.displayName = String(draft.displayName || '').trim();
      state.profile.businessStartYear = Number(draft.businessStartYear) || year;
      state.profile.filingType = draft.filingType;
      state.reserve.businessReserveAmount = draft.reserve === null ? 0 : draft.reserve;
      state.appSettings.hasCompletedOnboarding = true;
      state.appSettings.hasAcknowledgedDisclaimer = true;
      state.appSettings.selectedYear = year;

      const settings = Object.assign(
        store.defaultTaxSettings(),
        state.taxSettingsByYear[String(year)] || {}
      );
      settings.manualRevenueForecast = draft.revenue;
      settings.manualExpenseForecast = draft.expense;
      // 青色申告を選んだ人には、もっとも一般的な65万円控除を初期値として置いておく
      // （設定画面でいつでも変更できる）
      settings.blueReturnDeduction =
        draft.filingType === 'blue' ? 'doubleEntryElectronicFiling' : 'notEligible';
      state.taxSettingsByYear[String(year)] = settings;
    });

    saved(ok);
    uiState.onboarding = null;
    uiState.activeTab = 'home';
    render();
  }

  // --- 操作の受け口 --------------------------------------------------------

  const clickActions = {
    'nav-tab': function (el) {
      uiState.activeTab = el.dataset.tab;
      render();
    },
    'toggle-home-breakdown': function () {
      uiState.homeBreakdownOpen = !uiState.homeBreakdownOpen;
      render();
    },
    'set-history-segment': function (el) {
      uiState.historySegment = el.dataset.value;
      render();
    },
    'add-income': function () {
      openSheet('income', null);
    },
    'add-expense': function () {
      openSheet('expense', null);
    },
    'edit-income': function (el) {
      openSheet('income', el.dataset.id);
    },
    'edit-expense': function (el) {
      openSheet('expense', el.dataset.id);
    },
    'sheet-cancel': closeSheet,
    'sheet-save': saveSheet,
    'sheet-delete': deleteSheetEntry,
    'sheet-backdrop': function (el, event) {
      if (event.target === el) closeSheet();
    },
    'toggle-sheet-details': function () {
      uiState.sheet.showDetails = true;
      render();
    },
    'settings-year': function (el) {
      const delta = Number(el.dataset.delta);
      saved(
        store.update(function (state) {
          state.appSettings.selectedYear = state.appSettings.selectedYear + delta;
        })
      );
      render();
    },
    'settings-dependents': function (el) {
      const delta = Number(el.dataset.delta);
      const ctx = context();
      const next = Math.max(0, Math.min(10, ctx.tax.dependentsCount + delta));
      saved(store.updateTaxSettings(ctx.year, { dependentsCount: next }));
      render();
    },
    'reset-data': function () {
      if (!global.confirm('保存されているすべてのデータを削除します。よろしいですか？')) return;
      store.update(function (state) {
        const fresh = store.defaultState();
        Object.keys(fresh).forEach(function (key) {
          state[key] = fresh[key];
        });
      });
      uiState.activeTab = 'home';
      uiState.onboarding = null;
      render();
    },
    'onboarding-next': function () {
      uiState.onboarding.step = Math.min(
        views.onboarding.TOTAL_STEPS - 1,
        uiState.onboarding.step + 1
      );
      render();
    },
    'onboarding-back': function () {
      uiState.onboarding.step = Math.max(0, uiState.onboarding.step - 1);
      render();
    },
    'onboarding-choice': function (el) {
      uiState.onboarding[el.dataset.field] = el.dataset.value;
      render();
    },
    'onboarding-finish': finishOnboarding
  };

  const inputActions = {
    'sheet-amount': function (el) {
      uiState.sheet.draft.amount = readAmountInput(el);
      const saveButton = document.getElementById('sheet-save');
      if (saveButton) {
        saveButton.disabled = !(uiState.sheet.draft.amount > 0);
      }
    },
    'sheet-field': function (el) {
      uiState.sheet.draft[el.dataset.field] = el.value;
    },
    'onboarding-amount': function (el) {
      uiState.onboarding[el.dataset.field] = readAmountInput(el);
    },
    'onboarding-field': function (el) {
      uiState.onboarding[el.dataset.field] = el.value;
    },
    'forecast-amount': readAmountInput,
    'settings-tax-amount': readAmountInput,
    'settings-reserve-amount': readAmountInput
  };

  const changeActions = {
    'sheet-select': function (el) {
      uiState.sheet.draft[el.dataset.field] = el.value;
    },
    'sheet-toggle': function (el) {
      uiState.sheet.draft[el.dataset.field] = el.checked;
    },
    'onboarding-select': function (el) {
      uiState.onboarding[el.dataset.field] = el.value;
    },
    'forecast-toggle': function (el) {
      const ctx = context();
      const field = el.dataset.field;
      const autoForecast = services.annualForecast(ctx.actuals, null, null);
      const autoValue =
        field === 'manualRevenueForecast'
          ? autoForecast.revenueForecast
          : autoForecast.expenseForecast;

      const changes = {};
      // 手動に切り替えたときは、いまの自動予測値を初期値として引き継ぐ
      changes[field] = el.checked ? autoValue : null;
      saved(store.updateTaxSettings(ctx.year, changes));
      render();
    },
    'forecast-amount': function (el) {
      const ctx = context();
      const changes = {};
      changes[el.dataset.field] = format.parseAmount(el.value);
      saved(store.updateTaxSettings(ctx.year, changes));
      updateLiveValues();
    },
    'settings-profile': function (el) {
      saved(
        store.update(function (state) {
          state.profile[el.dataset.field] = el.value;
        })
      );
    },
    'settings-profile-select': function (el) {
      saved(
        store.update(function (state) {
          state.profile[el.dataset.field] =
            el.dataset.field === 'businessStartYear' ? Number(el.value) : el.value;
        })
      );
      render();
    },
    'settings-tax-select': function (el) {
      const ctx = context();
      const changes = {};
      if (el.dataset.field === 'birthYear') {
        changes.birthYear = el.value === '' ? null : Number(el.value);
      } else {
        changes[el.dataset.field] = el.value;
      }
      saved(store.updateTaxSettings(ctx.year, changes));
      render();
    },
    'settings-tax-toggle': function (el) {
      const ctx = context();
      const changes = {};
      changes[el.dataset.field] = el.checked;
      saved(store.updateTaxSettings(ctx.year, changes));
      render();
    },
    'settings-nhi-toggle': function (el) {
      const ctx = context();
      saved(
        store.updateTaxSettings(ctx.year, { hasSetNationalHealthInsuranceAmount: el.checked })
      );
      render();
    },
    'settings-tax-amount': function (el) {
      const ctx = context();
      const changes = {};
      changes[el.dataset.field] = format.parseAmount(el.value) || 0;
      saved(store.updateTaxSettings(ctx.year, changes));
      updateLiveValues();
    },
    'settings-reserve-amount': function (el) {
      const field = el.dataset.field;
      const value = format.parseAmount(el.value) || 0;
      saved(
        store.update(function (state) {
          state.reserve[field] = value;
        })
      );
      updateLiveValues();
    }
  };

  function dispatch(table, event) {
    const element = event.target.closest('[data-action]');
    if (!element) return;
    const handler = table[element.dataset.action];
    if (!handler) return;
    handler(element, event);
  }

  function start() {
    store.load();

    document.addEventListener('click', function (event) {
      dispatch(clickActions, event);
    });
    document.addEventListener('input', function (event) {
      dispatch(inputActions, event);
    });
    document.addEventListener('change', function (event) {
      dispatch(changeActions, event);
    });

    render();
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.app = { start, render, context, uiState, updateLiveValues };

  // すべてのスクリプトは defer で読み込むため、この時点ではまだ DOM 構築中の場合がある。
  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', start);
    } else {
      start();
    }
  }
})(typeof globalThis !== 'undefined' ? globalThis : this);
