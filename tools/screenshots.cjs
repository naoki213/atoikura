#!/usr/bin/env node
/**
 * ブラウザ（Chromium）で実際にアプリを操作し、動作確認とスクリーンショット撮影を行う。
 *
 *   node tools/screenshots.cjs [出力先ディレクトリ]
 *
 * 「オンボーディング → 売上100万円を登録 → 経費30万円を登録 → ホームに反映」までを
 * 自動で操作し、各画面を撮影する。数値が期待どおりでなければ異常終了する。
 */
'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');
/** playwright は環境によって置き場所が違うので、見つかったものを使う。 */
function loadPlaywright() {
  const candidates = [
    process.env.PLAYWRIGHT_MODULE,
    'playwright',
    '/opt/node22/lib/node_modules/playwright'
  ].filter(Boolean);

  for (const candidate of candidates) {
    try {
      return require(candidate);
    } catch (error) {
      // 次の候補を試す
    }
  }
  throw new Error('playwright が見つかりません。npm install playwright を実行してください。');
}

const { chromium } = loadPlaywright();

const root = path.resolve(__dirname, '..');
const outDir = path.resolve(process.argv[2] || path.join(root, 'screenshots'));

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.webmanifest': 'application/manifest+json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png'
};

/** テスト用の簡易静的サーバー（外部依存なし）。 */
function startServer() {
  const server = http.createServer((req, res) => {
    const urlPath = decodeURIComponent(req.url.split('?')[0]);
    let filePath = path.join(root, urlPath);
    if (urlPath.endsWith('/')) filePath = path.join(filePath, 'index.html');

    if (!filePath.startsWith(root)) {
      res.writeHead(403).end('Forbidden');
      return;
    }

    fs.readFile(filePath, (error, data) => {
      if (error) {
        res.writeHead(404).end('Not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream' });
      res.end(data);
    });
  });

  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => resolve({ server, port: server.address().port }));
  });
}

function assert(condition, message) {
  if (!condition) {
    throw new Error('確認に失敗しました: ' + message);
  }
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });
  const { server, port } = await startServer();
  const base = `http://127.0.0.1:${port}`;

  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    locale: 'ja-JP',
    timezoneId: 'Asia/Tokyo'
  });
  const page = await context.newPage();

  const consoleErrors = [];
  page.on('pageerror', (error) => consoleErrors.push(String(error)));
  page.on('console', (message) => {
    if (message.type() === 'error') consoleErrors.push(message.text());
  });

  const shot = async (name) => {
    await page.screenshot({ path: path.join(outDir, name + '.png') });
    console.log('  撮影: ' + name + '.png');
  };

  // --- 1. ユニットテストのページ ---------------------------------------
  await page.goto(base + '/tests/', { waitUntil: 'load' });
  const testSummary = await page.evaluate(() => window.__ATOIKURA_TEST_SUMMARY__);
  console.log(`テストページ: ${testSummary.passed} passed, ${testSummary.failed} failed`);
  assert(testSummary.failed === 0, 'ブラウザ上のユニットテストに失敗がある');
  await shot('00_tests');

  // --- 2. オンボーディング ---------------------------------------------
  await page.goto(base + '/', { waitUntil: 'load' });
  await page.waitForSelector('.onboarding');
  await shot('01_onboarding_welcome');

  await page.fill('#onboarding-name', 'やまだデザイン');
  await page.click('[data-action="onboarding-next"]');
  await page.waitForSelector('[data-action="onboarding-choice"]');
  await shot('02_onboarding_filing');

  await page.click('[data-value="blue"]');
  await page.click('[data-action="onboarding-next"]');
  await page.waitForSelector('#onboarding-reserve');
  await page.fill('#onboarding-reserve', '600000');
  await shot('03_onboarding_forecast');

  await page.click('[data-action="onboarding-next"]');
  await page.waitForSelector('[data-action="onboarding-finish"]');
  await shot('04_onboarding_done');
  await page.click('[data-action="onboarding-finish"]');

  // --- 3. ホーム（データなし） ------------------------------------------
  // 何も登録していない状態では、金額ではなく案内が出る（大きなマイナスで驚かせない）
  await page.waitForSelector('.hero .amount');
  const emptyAmount = (await page.textContent('.hero .amount')).trim();
  console.log('データ登録前のホーム: ' + emptyAmount);
  assert(emptyAmount === '—', 'データが無いときは金額ではなく案内を表示する');
  await shot('05_home_empty');

  // 実績の登録日は「今日」にして、経過月数から期待値を計算する（いつ実行しても通るように）
  const today = new Date();
  const elapsedMonths = today.getMonth() + 1;
  const todayISO =
    today.getFullYear() +
    '-' +
    String(elapsedMonths).padStart(2, '0') +
    '-' +
    String(Math.min(today.getDate(), 28)).padStart(2, '0');
  const yen = (value) => '¥' + value.toLocaleString('ja-JP');
  const expectedRevenue = Math.round((1000000 / elapsedMonths) * 12);
  const expectedExpense = Math.round((300000 / elapsedMonths) * 12);

  // --- 4. 売上100万円を登録 ---------------------------------------------
  await page.click('[data-action="add-income"]');
  await page.waitForSelector('#entry-amount');
  await page.fill('#entry-amount', '1000000');
  await page.fill('#entry-date', todayISO);
  await shot('06_entry_income');
  await page.click('[data-action="sheet-save"]');
  await page.waitForSelector('.hero .amount');

  // --- 5. 経費30万円を登録 ----------------------------------------------
  await page.click('[data-action="add-expense"]');
  await page.waitForSelector('#entry-amount');
  await page.fill('#entry-amount', '300000');
  await page.fill('#entry-date', todayISO);
  await page.selectOption('#entry-expense-category', 'supplies');
  await page.click('[data-action="sheet-save"]');
  await page.waitForSelector('.hero .amount');
  await shot('07_home_with_data');

  // 内訳の数字を確認する
  const rows = await page.$$eval('.row', (elements) =>
    elements.map((el) => ({
      label: el.querySelector('.row-label') ? el.querySelector('.row-label').textContent.trim() : '',
      value: el.querySelector('.row-value') ? el.querySelector('.row-value').textContent.trim() : ''
    }))
  );
  const findRow = (label) => rows.find((row) => row.label.startsWith(label));
  console.log('ホームの内訳:');
  ['今年の売上', '今年の経費', '予想利益', '税金・社会保険として確保', '事業用に残すお金'].forEach(
    (label) => {
      const row = findRow(label);
      console.log('  ' + label + ': ' + (row ? row.value : '(見つからない)'));
    }
  );

  // 経過月数ぶんの実績なので、1年分へ換算された金額になるはず
  assert(
    findRow('今年の売上').value === yen(expectedRevenue),
    '売上予測が年間換算されている（期待: ' + yen(expectedRevenue) + '）'
  );
  assert(
    findRow('今年の経費').value === yen(expectedExpense),
    '経費予測が年間換算されている（期待: ' + yen(expectedExpense) + '）'
  );
  assert(
    findRow('予想利益').value === yen(expectedRevenue - expectedExpense),
    '予想利益 = 売上 − 経費'
  );
  assert(findRow('事業用に残すお金').value === '¥600,000', 'オンボーディングの予備資金が反映される');

  // --- 6. 履歴 ----------------------------------------------------------
  await page.click('[data-action="nav-tab"][data-tab="history"]');
  await page.waitForSelector('.entry-row');
  const entryCount = await page.$$eval('.entry-row', (els) => els.length);
  assert(entryCount === 2, '履歴に2件表示される（実際: ' + entryCount + '件）');
  await shot('08_history');

  // --- 7. 予測 ----------------------------------------------------------
  await page.click('[data-action="nav-tab"][data-tab="forecast"]');
  await page.waitForSelector('[data-action="forecast-toggle"]');
  await shot('09_forecast');

  // 手動予測へ切り替えて、ホームに反映されることを確認する
  await page.check('#forecast-revenue-toggle');
  await page.waitForSelector('#forecast-revenue');
  await page.fill('#forecast-revenue', '8000000');
  await page.dispatchEvent('#forecast-revenue', 'change');
  await page.waitForTimeout(100);
  await shot('10_forecast_manual');

  await page.click('[data-action="nav-tab"][data-tab="home"]');
  await page.waitForSelector('.hero .amount');
  const manualRows = await page.$$eval('.row', (elements) =>
    elements.map((el) => ({
      label: el.querySelector('.row-label') ? el.querySelector('.row-label').textContent.trim() : '',
      value: el.querySelector('.row-value') ? el.querySelector('.row-value').textContent.trim() : ''
    }))
  );
  const manualRevenue = manualRows.find((row) => row.label.startsWith('今年の売上'));
  assert(manualRevenue.value === '¥8,000,000', '手動予測がホームに反映される');
  console.log('手動予測に切り替え後のホームの売上: ' + manualRevenue.value);

  // --- 8. 設定 ----------------------------------------------------------
  await page.click('[data-action="nav-tab"][data-tab="settings"]');
  await page.waitForSelector('#settings-name');
  await shot('11_settings');

  // 国民健康保険を入力して、税額が増えることを確認する
  const taxBefore = await page.textContent('[data-live="tax-total"]');
  await page.check('#settings-nhi-toggle');
  await page.waitForSelector('#settings-nhi');
  await page.fill('#settings-nhi', '300000');
  await page.dispatchEvent('#settings-nhi', 'change');
  await page.waitForTimeout(100);
  const taxAfter = await page.textContent('[data-live="tax-total"]');
  console.log('国民健康保険の入力前後の税額: ' + taxBefore + ' → ' + taxAfter);
  assert(taxBefore !== taxAfter, '国民健康保険の入力が税額に反映される');
  await shot('12_settings_insurance');

  // --- 9. 再読み込みしてもデータが残る ----------------------------------
  await page.reload({ waitUntil: 'load' });
  await page.waitForSelector('.hero .amount, .app-header');
  await page.click('[data-action="nav-tab"][data-tab="history"]');
  await page.waitForSelector('.entry-row');
  const entryCountAfterReload = await page.$$eval('.entry-row', (els) => els.length);
  assert(entryCountAfterReload === 2, '再読み込み後もデータが残っている');
  console.log('再読み込み後も履歴は ' + entryCountAfterReload + ' 件');

  // --- 10. ダークモード -------------------------------------------------
  await context.close();
  const darkContext = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    locale: 'ja-JP',
    timezoneId: 'Asia/Tokyo',
    colorScheme: 'dark'
  });
  const darkPage = await darkContext.newPage();
  await darkPage.goto(base + '/', { waitUntil: 'load' });
  await darkPage.waitForSelector('.onboarding');
  await darkPage.screenshot({ path: path.join(outDir, '13_dark_onboarding.png') });
  console.log('  撮影: 13_dark_onboarding.png');

  // --- 11. 小さい画面（iPhone SE 相当） ---------------------------------
  const smallContext = await browser.newContext({
    viewport: { width: 320, height: 568 },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    locale: 'ja-JP',
    timezoneId: 'Asia/Tokyo'
  });
  const smallPage = await smallContext.newPage();
  await smallPage.goto(base + '/', { waitUntil: 'load' });
  await smallPage.waitForSelector('.onboarding');
  await smallPage.screenshot({ path: path.join(outDir, '14_small_screen.png') });
  console.log('  撮影: 14_small_screen.png');

  await browser.close();
  server.close();

  if (consoleErrors.length > 0) {
    console.error('\nブラウザのエラー:');
    consoleErrors.forEach((error) => console.error('  ' + error));
    process.exit(1);
  }

  console.log('\nすべての確認項目を通過しました。');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
