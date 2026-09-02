/**
 * 設定画面。詳細を設定していなくてもアプリが成立するよう、すべて初期値を持つ。
 * 変更は入力のたびに即保存する（保存ボタンを押し忘れて消える事故を防ぐ）。
 */
(function (global) {
  'use strict';

  const c = global.Atoikura.components;
  const store = global.Atoikura.store;
  const { currency } = global.Atoikura.format;

  function yearOptions(from, to) {
    const options = [];
    for (let year = to; year >= from; year -= 1) {
      options.push({ value: String(year), label: year + '年' });
    }
    return options;
  }

  function render(ctx) {
    const state = ctx.state;
    const tax = ctx.tax;
    const thisYear = store.currentYear();

    const profileCard = c.card({
      header: 'プロフィール',
      body:
        c.textField({
          id: 'settings-name',
          label: '表示名（任意）',
          action: 'settings-profile',
          field: 'displayName',
          value: state.profile.displayName,
          placeholder: '屋号やお名前'
        }) +
        c.selectField({
          id: 'settings-start-year',
          label: '事業開始年',
          action: 'settings-profile-select',
          field: 'businessStartYear',
          value: String(state.profile.businessStartYear),
          options: yearOptions(thisYear - 30, thisYear)
        }) +
        c.stepperRow({
          label: '対象年度',
          action: 'settings-year',
          display: ctx.year + '年'
        })
    });

    const filingCard = c.card({
      header: '申告方法',
      body:
        c.selectField({
          id: 'settings-filing',
          label: '申告の種類',
          action: 'settings-profile-select',
          field: 'filingType',
          value: state.profile.filingType,
          options: [
            { value: 'blue', label: '青色申告' },
            { value: 'white', label: '白色申告' }
          ]
        }) +
        (state.profile.filingType === 'blue'
          ? c.selectField({
              id: 'settings-blue',
              label: '青色申告特別控除',
              action: 'settings-tax-select',
              field: 'blueReturnDeduction',
              value: tax.blueReturnDeduction,
              options: store.BLUE_DEDUCTION_OPTIONS.map(function (item) {
                return { value: item.id, label: item.name };
              })
            })
          : ''),
      footer:
        state.profile.filingType === 'blue'
          ? '65万円控除には複式簿記での記帳とe-Tax申告（または優良な電子帳簿の保存）が必要です。'
          : '白色申告では青色申告特別控除は適用されません。'
    });

    const personalCard = c.card({
      header: '税計算用の情報（' + ctx.year + '年）',
      body:
        c.selectField({
          id: 'settings-prefecture',
          label: '都道府県',
          action: 'settings-tax-select',
          field: 'prefecture',
          value: tax.prefecture,
          options: store.PREFECTURES.map(function (name) {
            return { value: name, label: name };
          })
        }) +
        c.selectField({
          id: 'settings-birth-year',
          label: '生年',
          action: 'settings-tax-select',
          field: 'birthYear',
          value: tax.birthYear === null ? '' : String(tax.birthYear),
          options: [{ value: '', label: '未設定' }].concat(
            yearOptions(thisYear - 100, thisYear - 15)
          )
        }) +
        c.stepperRow({
          label: '扶養人数',
          action: 'settings-dependents',
          display: tax.dependentsCount + '人'
        }) +
        c.toggleRow({
          id: 'settings-spouse',
          label: '配偶者がいる',
          action: 'settings-tax-toggle',
          field: 'hasSpouse',
          checked: tax.hasSpouse
        }),
      footer: '配偶者控除・扶養控除は、所得制限や年齢区分を考慮しない概算の金額で計算しています。'
    });

    const insuranceCard = c.card({
      header: '社会保険',
      body:
        c.toggleRow({
          id: 'settings-pension',
          label: '国民年金に加入している',
          action: 'settings-tax-toggle',
          field: 'isNationalPensionEnrolled',
          checked: tax.isNationalPensionEnrolled
        }) +
        c.toggleRow({
          id: 'settings-nhi-toggle',
          label: '国民健康保険料を入力する',
          action: 'settings-nhi-toggle',
          field: 'hasSetNationalHealthInsuranceAmount',
          checked: tax.hasSetNationalHealthInsuranceAmount
        }) +
        (tax.hasSetNationalHealthInsuranceAmount
          ? c.amountField({
              id: 'settings-nhi',
              label: '国民健康保険料（年額）',
              action: 'settings-tax-amount',
              field: 'nationalHealthInsuranceAnnualAmount',
              value: tax.nationalHealthInsuranceAnnualAmount
            })
          : ''),
      footer:
        '国民健康保険料は自治体ごとに大きく異なるため自動計算していません。' +
        'お住まいの自治体のサイトなどで年額の目安を調べて入力してください。未入力の場合は0円として概算します。'
    });

    const businessTaxCard = c.card({
      header: '個人事業税',
      body: c.selectField({
        id: 'settings-business-tax',
        label: '業種区分',
        action: 'settings-tax-select',
        field: 'businessTaxCategory',
        value: tax.businessTaxCategory,
        options: store.BUSINESS_TAX_OPTIONS.map(function (item) {
          return { value: item.id, label: item.name };
        })
      }),
      footer: '正確な業種区分は、税務署や都道府県税事務所にご確認ください。'
    });

    const reserveCard = c.card({
      header: '確保しておくお金',
      body:
        c.amountField({
          id: 'settings-reserve',
          label: '事業用に残しておきたい予備資金',
          action: 'settings-reserve-amount',
          field: 'businessReserveAmount',
          value: state.reserve.businessReserveAmount
        }) +
        c.amountField({
          id: 'settings-other-reserve',
          label: 'その他確保したい資金（任意）',
          action: 'settings-reserve-amount',
          field: 'otherReserveAmount',
          value: state.reserve.otherReserveAmount
        }),
      footer: 'ここで設定した金額は「今年あと使えるお金」から差し引かれます。'
    });

    const aboutCard = c.card({
      header: 'このアプリについて',
      body:
        '<div class="field">' +
        c.disclaimerText() +
        '<p class="disclaimer" style="margin-top:10px">入力したデータはこの端末のブラウザ内にのみ保存され、' +
        'どこにも送信されません。ブラウザのデータを消すと失われます。</p>' +
        '</div>' +
        c.row('税制の対応年度', '2026年分（令和8年分）') +
        c.row('バージョン', 'Web 1.0') +
        '<div class="field">' +
        '<button type="button" class="btn btn-block btn-danger" data-action="reset-data">' +
        'すべてのデータを削除</button>' +
        '</div>'
    });

    const summaryNote =
      '<div class="notice">現在の設定での税金・社会保険の概算は ' +
      '<strong data-live="tax-total">' +
      currency(ctx.breakdown.taxAndSocialInsurance) +
      '</strong> です。</div>';

    return (
      '<h2 class="screen-title">設定</h2>' +
      summaryNote +
      profileCard +
      filingCard +
      personalCard +
      insuranceCard +
      businessTaxCard +
      reserveCard +
      aboutCard
    );
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.views = global.Atoikura.views || {};
  global.Atoikura.views.settings = { render };
})(typeof globalThis !== 'undefined' ? globalThis : this);
