/**
 * 依存ライブラリを使わない最小限のテストハーネス。
 * ブラウザ（tests/index.html）と Node.js（tools/run-tests.cjs）の両方で動く。
 */
(function (global) {
  'use strict';

  const tests = [];

  function test(name, fn) {
    tests.push({ name, fn });
  }

  class AssertionError extends Error {}

  function fail(message) {
    throw new AssertionError(message);
  }

  function assertEqual(actual, expected, message) {
    if (actual !== expected) {
      fail(
        (message ? message + ': ' : '') +
          'expected ' + JSON.stringify(expected) + ' but got ' + JSON.stringify(actual)
      );
    }
  }

  function assertTrue(value, message) {
    if (value !== true) {
      fail((message ? message + ': ' : '') + 'expected true but got ' + JSON.stringify(value));
    }
  }

  function assertFalse(value, message) {
    if (value !== false) {
      fail((message ? message + ': ' : '') + 'expected false but got ' + JSON.stringify(value));
    }
  }

  function assertLessThan(actual, limit, message) {
    if (!(actual < limit)) {
      fail((message ? message + ': ' : '') + 'expected ' + actual + ' < ' + limit);
    }
  }

  function assertGreaterThan(actual, limit, message) {
    if (!(actual > limit)) {
      fail((message ? message + ': ' : '') + 'expected ' + actual + ' > ' + limit);
    }
  }

  /** 登録済みのテストをすべて実行して結果を返す。 */
  function runAll() {
    const results = [];
    let passed = 0;
    let failed = 0;

    for (const item of tests) {
      try {
        item.fn();
        results.push({ name: item.name, ok: true });
        passed += 1;
      } catch (error) {
        results.push({ name: item.name, ok: false, message: String(error.message || error) });
        failed += 1;
      }
    }

    return { passed, failed, total: tests.length, results };
  }

  global.Atoikura = global.Atoikura || {};
  global.Atoikura.testing = {
    test,
    assertEqual,
    assertTrue,
    assertFalse,
    assertLessThan,
    assertGreaterThan,
    runAll
  };
})(typeof globalThis !== 'undefined' ? globalThis : this);
