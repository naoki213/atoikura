/**
 * 表示フォーマットの共通処理。表記をアプリ全体で統一するために必ずここを通す。
 */
(function (global) {
  'use strict';

  /** 例: 3420000 → "¥3,420,000" / -1000 → "-¥1,000" */
  function currency(value) {
    const amount = Math.round(value || 0);
    const sign = amount < 0 ? '-' : '';
    return sign + '¥' + Math.abs(amount).toLocaleString('ja-JP');
  }

  /** 端末のローカル日付を 'YYYY-MM-DD' で返す（UTC変換を経由しない）。 */
  function todayISO() {
    const now = new Date();
    return (
      now.getFullYear() +
      '-' +
      String(now.getMonth() + 1).padStart(2, '0') +
      '-' +
      String(now.getDate()).padStart(2, '0')
    );
  }

  /** 'YYYY-MM-DD' → "3月1日" */
  function shortDate(iso) {
    const month = Number(String(iso).slice(5, 7));
    const day = Number(String(iso).slice(8, 10));
    return month + '月' + day + '日';
  }

  /** 'YYYY-MM' → "2026年3月" */
  function monthLabel(yearMonth) {
    const year = String(yearMonth).slice(0, 4);
    const month = Number(String(yearMonth).slice(5, 7));
    return year + '年' + month + '月';
  }

  /** HTML へ埋め込む文字列のエスケープ（ユーザー入力を表示するときに必ず使う）。 */
  function escapeHTML(value) {
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  /** 入力文字列から数字だけを取り出して整数にする。空なら null。 */
  function parseAmount(text) {
    const digits = String(text == null ? '' : text).replace(/[^0-9]/g, '');
    if (digits === '') return null;
    return Number(digits);
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.format = {
    currency,
    todayISO,
    shortDate,
    monthLabel,
    escapeHTML,
    parseAmount
  };
})(typeof globalThis !== 'undefined' ? globalThis : this);
