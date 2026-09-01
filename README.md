# あといくら

日本の個人事業主・フリーランス向けiPhoneアプリ。

> 今年、あといくら使える？

売上・経費・税金・社会保険・事業用予備資金を踏まえて、
「今の状況なら実際にあといくら使っても大丈夫そうか」を直感的に把握できるようにする。
確定申告書の作成や複式簿記の会計帳簿づくりを目的としたアプリではない。

## App Store表示名（候補）

あといくら - 個人事業主の税金・手取り予測

## 技術構成

- Swift / SwiftUI（iOS 17+）
- SwiftData（永続化）
- StoreKit 2（Pro課金・Ver1.0では土台のみ、実際の商品登録はApp Store Connect側で行う）
- 外部ライブラリ: 使用しない（Apple標準技術のみ）

税計算ロジック（TaxEngine）はSwiftUI/SwiftData/UIKitに一切依存しない
**独立したローカルSwift Package**として実装している。UI層から完全に分離し、
将来的にmacOSやコマンドラインからも検証できる構造にしている。

## フォルダ構成

```
atoikura/
  project.yml            # XcodeGenのプロジェクト定義（.xcodeprojはこれを元に生成する）
  Atoikura/               # アプリ本体
    App/                  # App/Sceneのエントリーポイント、ルート画面
    Models/               # SwiftDataモデル（@Model）
    Views/                # 画面（Onboarding/Home/History/Forecast/Settings/Shared）
    ViewModels/            # 画面ごとの状態・振る舞い（ビジネスロジックはServices/TaxEngineへ委譲）
    Services/              # 集計・予測・税計算結果の組み立てなど
    Utilities/             # フォーマッタ等の小さな共通処理
    Resources/             # Assets.xcassets 等
  AtoikuraTests/          # アプリ側のユニットテスト（SwiftData・集計ロジックなど）
  TaxEngine/              # 税計算ロジック本体（独立Swift Package）
    Sources/TaxEngine/
    Tests/TaxEngineTests/  # 境界値を中心としたユニットテスト
```

Viewには表示ロジックのみを置き、税額計算・年間集計などのビジネスロジックは
`Services/` と `TaxEngine` に置く方針を徹底している。

## データモデル

SwiftDataモデルは以下の6種類。「候補」として挙げられていた `AnnualForecast` は
専用モデルにせず、年間予測の手動上書き値（`manualRevenueForecast` /
`manualExpenseForecast`）として `TaxSettings` に統合した
（年度ごとに1件ずつという性質が`TaxSettings`と同じで、モデルを増やすメリットが
薄いと判断したため）。

| モデル | 役割 |
|---|---|
| `UserProfile` | 表示名・事業開始年・申告方式（シングルトン） |
| `IncomeTransaction` | 売上の1件の記録 |
| `ExpenseTransaction` | 経費の1件の記録（カテゴリー・事業割合を含む） |
| `TaxSettings` | 年度ごとの税計算用プロフィール（青色控除区分・扶養・国保手入力額・年間予測手動値など） |
| `ReserveSettings` | 事業用に残したい予備資金・その他確保したい資金（シングルトン） |
| `AppSettings` | オンボーディング完了フラグ・対象年度などアプリ全体の状態（シングルトン） |

金額はすべて `Decimal` 型で保持し、浮動小数点誤差を避けている。

## TaxEngine概要

`TaxEngine` は年度ごとの税制ルール（`TaxRuleSet`）を切り替え可能な構造にしている。

```
TaxEngine（Swift Package、Apple UIフレームワーク非依存）
  TaxProfile               入力（事業所得・申告方式・扶養状況など）
  TaxRuleSet（プロトコル）  年度ごとの税率・控除額テーブル
  TaxRules2026              2026年分のルール実装
  IncomeTaxCalculator        所得税（＋復興特別所得税）
  ResidentTaxCalculator      住民税
  NationalPensionCalculator  国民年金
  NationalHealthInsuranceCalculator  国民健康保険（自治体差が大きいためユーザー手入力を反映するのみ）
  BusinessTaxCalculator      個人事業税
  TaxCalculationResult       課税所得・適用控除・適用税率・計算年度を含む結果
```

（TaxEngineの計算本体はPhase4-6で実装。詳細な設計判断は `DEVELOPMENT.md` を参照。）

## 対応税制年度

- 2026年分（令和8年分）

税率・控除額などの数値は原則として一次情報（国税庁等）を確認した上で実装するが、
一部の項目はネットワーク制約により一次情報へ直接アクセスできず、複数の二次情報を
突き合わせて実装した。**要検証項目は `DEVELOPMENT.md` の「税制データの検証状況」に
一覧化しているので、App Store公開前に必ず国税庁等の一次情報で再確認すること。**

## 現在実装済み機能

- プロジェクト基盤（XcodeGen構成、SwiftDataモデル、TaxEngineパッケージの型定義）
- オンボーディング（表示名・事業開始年 / 申告方法 / 年間見込み・予備資金 / 完了、
  「あとで設定する」対応）

（他の機能はPhase進行に応じて追記する）

## 未実装機能 / Ver2予定

Ver1.0では以下は実装しない（コード上拡張しやすい構造にはするが、機能自体は作らない）。

- AIチャット、レシートOCR、銀行/クレジットカードAPI連携
- 確定申告書作成・電子申告、請求書発行、売掛金の高度管理
- チーム共有、Web版、Android版

Ver2.0の主力機能候補: 「もしも」シミュレーション（支出・売上・控除変更前後の比較）。

## ビルド方法

このリポジトリはXcodeプロジェクトファイル（`.xcodeproj`）を直接コミットせず、
[XcodeGen](https://github.com/yonaskolb/XcodeGen) の `project.yml` から生成する方針。

```sh
brew install xcodegen
cd atoikura
xcodegen generate
open Atoikura.xcodeproj
```

TaxEngineだけを単体でビルド・テストする場合（Swiftツールチェーンがあれば
Xcode不要でmacOS/Linuxどちらでも可能）:

```sh
cd TaxEngine
swift test
```

> 開発時の注意: このプロジェクトの一部の開発ターンはXcode/Swiftツールチェーンの
> 無いLinux環境で行われている。その場合コードは書けてもXcodeでの実機ビルド確認は
> できないため、静的なコードレビューのみで進めた回がある。詳細は `DEVELOPMENT.md` を参照。
