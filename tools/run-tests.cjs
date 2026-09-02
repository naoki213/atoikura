#!/usr/bin/env node
/**
 * Node.js でユニットテストを実行する（CI と開発中の確認用）。
 * ブラウザで確認したい場合は tests/index.html を開く。
 *
 *   node tools/run-tests.cjs
 */
'use strict';

const path = require('path');

const root = path.resolve(__dirname, '..');

// アプリのソースはすべて globalThis.Atoikura に登録される形なので、
// 依存順に読み込むだけでテスト対象がそろう。
const files = [
  'assets/js/tax/rules-2026.js',
  'assets/js/tax/engine.js',
  'assets/js/services.js',
  'tests/harness.js',
  'tests/tax-tests.js',
  'tests/services-tests.js'
];

for (const file of files) {
  require(path.join(root, file));
}

const summary = globalThis.Atoikura.testing.runAll();

for (const result of summary.results) {
  if (result.ok) {
    console.log('  ✓ ' + result.name);
  } else {
    console.log('  ✗ ' + result.name);
    console.log('      ' + result.message);
  }
}

console.log('');
console.log(`${summary.passed} passed, ${summary.failed} failed (${summary.total} total)`);

process.exit(summary.failed === 0 ? 0 : 1);
