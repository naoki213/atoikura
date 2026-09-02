#!/usr/bin/env node
/**
 * アプリアイコンのPNGを生成する（ホーム画面に追加したときに使われる）。
 *
 *   node tools/make-icons.cjs
 *
 * 画像編集ソフトを使わずに済むよう、SVGをブラウザで描画して書き出している。
 * iOS側で角丸にトリミングされるため、PNGは角を丸めない正方形にしておく。
 */
'use strict';

const path = require('path');
const fs = require('fs');
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

const outDir = path.resolve(__dirname, '..', 'assets', 'icons');
const SIZES = [180, 512];

function svgMarkup(size) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 512 512">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#2f7bb0"/>
        <stop offset="1" stop-color="#22557c"/>
      </linearGradient>
    </defs>
    <rect width="512" height="512" fill="url(#bg)"/>
    <text x="256" y="300" text-anchor="middle" font-family="-apple-system, 'Hiragino Sans', sans-serif"
          font-size="220" font-weight="700" fill="#ffffff">¥</text>
    <text x="256" y="392" text-anchor="middle" font-family="-apple-system, 'Hiragino Sans', sans-serif"
          font-size="72" font-weight="600" fill="rgba(255,255,255,0.82)">あといくら</text>
  </svg>`;
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch();

  for (const size of SIZES) {
    const page = await browser.newPage({ viewport: { width: size, height: size } });
    await page.setContent(
      '<body style="margin:0">' + svgMarkup(size) + '</body>',
      { waitUntil: 'load' }
    );
    const file = path.join(outDir, 'icon-' + size + '.png');
    await page.screenshot({ path: file });
    console.log('生成: ' + path.relative(path.resolve(__dirname, '..'), file));
    await page.close();
  }

  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
