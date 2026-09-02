/**
 * データの保存と取り出し。すべて端末内（localStorage）に保存し、外部へは送信しない。
 *
 * 売上・経費という機密性の高い情報を扱うため、サーバーへの送信・解析ツール・広告SDKは
 * 一切使わない方針（DEVELOPMENT.md 参照）。
 */
(function (global) {
  'use strict';

  const STORAGE_KEY = 'atoikura.v1';

  const EXPENSE_CATEGORIES = [
    { id: 'purchases', name: '仕入' },
    { id: 'supplies', name: '消耗品' },
    { id: 'communication', name: '通信費' },
    { id: 'travel', name: '交通費' },
    { id: 'advertising', name: '広告宣伝費' },
    { id: 'outsourcing', name: '外注費' },
    { id: 'rent', name: '地代家賃' },
    { id: 'utilities', name: '水道光熱費' },
    { id: 'entertainment', name: '接待交際費' },
    { id: 'other', name: 'その他' }
  ];

  const PREFECTURES = [
    '未設定', '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県',
    '岐阜県', '静岡県', '愛知県', '三重県',
    '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
    '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県',
    '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  const BLUE_DEDUCTION_OPTIONS = [
    { id: 'notEligible', name: '適用なし（0円）' },
    { id: 'simplifiedBookkeeping', name: '10万円控除（簡易な記帳）' },
    { id: 'doubleEntryPaperFiling', name: '55万円控除（複式簿記・書面提出）' },
    { id: 'doubleEntryElectronicFiling', name: '65万円控除（複式簿記・e-Tax/電子帳簿）' }
  ];

  const BUSINESS_TAX_OPTIONS = [
    { id: 'rate5Percent', name: '5%（請負業・デザイン業・コンサルタント業など）' },
    { id: 'rate4Percent', name: '4%（畜産業・水産業など）' },
    { id: 'rate3Percent', name: '3%（あんま・マッサージ指圧師業など）' },
    { id: 'exempt', name: '非課税業種（著述業など）' }
  ];

  function currentYear() {
    return new Date().getFullYear();
  }

  /** 何も保存されていないときの初期状態。詳細設定なしでもアプリが成立する値にする。 */
  function defaultState() {
    return {
      version: 1,
      appSettings: {
        hasCompletedOnboarding: false,
        hasAcknowledgedDisclaimer: false,
        selectedYear: currentYear()
      },
      profile: {
        displayName: '',
        businessStartYear: currentYear(),
        filingType: 'blue'
      },
      reserve: {
        businessReserveAmount: 0,
        otherReserveAmount: 0
      },
      taxSettingsByYear: {},
      incomes: [],
      expenses: []
    };
  }

  /** 年度ごとの税計算用設定の初期値。 */
  function defaultTaxSettings() {
    return {
      blueReturnDeduction: 'notEligible',
      prefecture: '未設定',
      birthYear: null,
      dependentsCount: 0,
      hasSpouse: false,
      isNationalPensionEnrolled: true,
      nationalHealthInsuranceAnnualAmount: 0,
      hasSetNationalHealthInsuranceAmount: false,
      businessTaxCategory: 'rate5Percent',
      manualRevenueForecast: null,
      manualExpenseForecast: null
    };
  }

  let state = defaultState();
  /** localStorage が使えない環境（プライベートブラウズ等）でも動かすためのフラグ。 */
  let storageAvailable = true;

  function load() {
    try {
      const raw = global.localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        state = Object.assign(defaultState(), parsed);
        // 後から追加した項目が欠けていても壊れないように補完する
        state.appSettings = Object.assign(defaultState().appSettings, parsed.appSettings);
        state.profile = Object.assign(defaultState().profile, parsed.profile);
        state.reserve = Object.assign(defaultState().reserve, parsed.reserve);
        state.taxSettingsByYear = parsed.taxSettingsByYear || {};
        state.incomes = Array.isArray(parsed.incomes) ? parsed.incomes : [];
        state.expenses = Array.isArray(parsed.expenses) ? parsed.expenses : [];
      }
    } catch (error) {
      // 壊れたデータや localStorage 無効時は初期状態のまま動かす（クラッシュさせない）
      storageAvailable = false;
      state = defaultState();
    }
    return state;
  }

  function save() {
    try {
      global.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
      storageAvailable = true;
      return true;
    } catch (error) {
      storageAvailable = false;
      return false;
    }
  }

  function getState() {
    return state;
  }

  function isStorageAvailable() {
    return storageAvailable;
  }

  /** state を書き換えて保存する。保存できたかどうかを返す。 */
  function update(mutator) {
    mutator(state);
    return save();
  }

  /** 指定年度の税設定を取得する（無ければ初期値を返す。保存はしない）。 */
  function taxSettingsFor(year) {
    return Object.assign(defaultTaxSettings(), state.taxSettingsByYear[String(year)] || {});
  }

  /** 指定年度の税設定を書き換える。 */
  function updateTaxSettings(year, changes) {
    return update((s) => {
      const key = String(year);
      s.taxSettingsByYear[key] = Object.assign(
        defaultTaxSettings(),
        s.taxSettingsByYear[key] || {},
        changes
      );
    });
  }

  function newId() {
    return 'id-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8);
  }

  function addIncome(entry) {
    return update((s) => {
      s.incomes.push(Object.assign({ id: newId(), createdAt: new Date().toISOString() }, entry));
    });
  }

  function updateIncome(id, changes) {
    return update((s) => {
      const target = s.incomes.find((t) => t.id === id);
      if (target) Object.assign(target, changes, { updatedAt: new Date().toISOString() });
    });
  }

  function deleteIncome(id) {
    return update((s) => {
      s.incomes = s.incomes.filter((t) => t.id !== id);
    });
  }

  function addExpense(entry) {
    return update((s) => {
      s.expenses.push(Object.assign({ id: newId(), createdAt: new Date().toISOString() }, entry));
    });
  }

  function updateExpense(id, changes) {
    return update((s) => {
      const target = s.expenses.find((t) => t.id === id);
      if (target) Object.assign(target, changes, { updatedAt: new Date().toISOString() });
    });
  }

  function deleteExpense(id) {
    return update((s) => {
      s.expenses = s.expenses.filter((t) => t.id !== id);
    });
  }

  function expenseCategoryName(id) {
    const found = EXPENSE_CATEGORIES.find((c) => c.id === id);
    return found ? found.name : 'その他';
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.store = {
    STORAGE_KEY,
    EXPENSE_CATEGORIES,
    PREFECTURES,
    BLUE_DEDUCTION_OPTIONS,
    BUSINESS_TAX_OPTIONS,
    currentYear,
    defaultState,
    defaultTaxSettings,
    load,
    save,
    getState,
    isStorageAvailable,
    update,
    taxSettingsFor,
    updateTaxSettings,
    addIncome,
    updateIncome,
    deleteIncome,
    addExpense,
    updateExpense,
    deleteExpense,
    expenseCategoryName
  };
})(typeof globalThis !== 'undefined' ? globalThis : this);
