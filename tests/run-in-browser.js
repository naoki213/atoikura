/** tests/index.html を開いたときにテストを実行して結果を描画する。 */
(function () {
  'use strict';

  const summary = window.Atoikura.testing.runAll();

  const summaryElement = document.getElementById('summary');
  summaryElement.textContent =
    summary.failed === 0
      ? 'すべて合格: ' + summary.passed + ' 件'
      : summary.failed + ' 件失敗 / ' + summary.total + ' 件中';
  summaryElement.className = 'summary ' + (summary.failed === 0 ? 'ok' : 'ng');

  // テストの実行結果をそのまま表示するだけなので、テキストは textContent で入れる
  const list = document.getElementById('results');
  summary.results.forEach(function (result) {
    const item = document.createElement('li');
    item.className = result.ok ? 'ok' : 'ng';
    item.textContent = (result.ok ? '✓ ' : '✗ ') + result.name;
    if (!result.ok) {
      const message = document.createElement('span');
      message.className = 'message';
      message.textContent = result.message;
      item.appendChild(message);
    }
    list.appendChild(item);
  });

  // 自動チェック（Playwright など）から結果を参照できるようにしておく
  window.__ATOIKURA_TEST_SUMMARY__ = summary;
})();
