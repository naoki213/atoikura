# DEVELOPMENT.md

Claude CodeやCodexなど、別のAIエージェントが途中から参加しても状況が分かるように、
開発ルール・設計判断・注意点をここに記録する。作業を始める前に必ず読むこと。

## 実行環境に関する重大な制約

このプロジェクトの開発は、Xcode・Swiftツールチェーンの**無い**Linuxのリモートコンテナで
行われている回がある（`swift`, `xcodebuild` コマンドが存在せず、`download.swift.org` への
ネットワークアクセスもプロキシポリシーでブロックされている）。

その場合、実際の `xcodebuild` によるビルドやiOSシミュレータでの動作確認は**できない**。
コードは実運用品質で書くが、「ビルドして確認した」という報告は、実際にビルドできた場合
にのみ行うこと。ビルドできなかった場合は、静的レビュー（import・型・API仕様の突き合わせ）
で確認した旨を正直に報告する。

Xcode/Swiftが使える環境（macOSでの開発、または将来Linux版Swiftツールチェーンが
使えるセッション）に引き継いだ場合は、必ず以下を実行して確認すること。

```sh
cd TaxEngine && swift test        # まずTaxEngine単体（Apple UI非依存なのでどこでも動く）
cd .. && xcodegen generate         # .xcodeprojを生成
xcodebuild -scheme Atoikura -destination 'platform=iOS Simulator,name=iPhone 15' build test
```

## 開発ルール（サマリー）

- Viewにビジネスロジックを書かない。税計算は`TaxEngine`、集計・予測は`Atoikura/Services`に置く。
- `TaxEngine` は `import SwiftUI` / `import SwiftData` / `import UIKit` を絶対に行わない。
  UI層からの独立性・単体テスト容易性を保つための最重要ルール。
- 金額は `Decimal` で扱う（`Double` を金額計算に使わない）。
- マジックナンバー（税率・控除額など）は `TaxRules2026` 等のルールファイルに閉じ込め、
  ViewやServicesに直接書かない。
- 巨大ファイル・巨大Viewを作らない。1ファイルが長くなってきたら分割を検討する。
- 強制アンラップ（`!`）は極力使わない。
- 日本語UIを基本とし、Ver1.0では `Localizable.strings` によるローカライズ基盤は導入しない
  （英語対応の予定がなく、抽象化のコストに見合わないため）。将来多言語化する場合に導入する。
- ダミーデータ・Previewデータは本番コードと明確に分離する（`#Preview` 内 or 専用ファイル）。

## 主な設計判断

### データモデルを6種類に統一（`AnnualForecast` を独立モデルにしなかった理由）

要求定義では `AnnualForecast` も候補として挙がっていたが、年間の売上・経費予測の
「手動上書き値」は年度ごとに1件で足り、性質が`TaxSettings`（同じく年度ごとに1件）と
ほぼ同じだったため、`TaxSettings.manualRevenueForecast` / `manualExpenseForecast` に
統合した。自動予測値（実績ベースの単純年間換算）はモデルに保存せず、都度
`Services` 層で計算する（保存すると実績とズレたときに再計算漏れが起きるリスクがあるため）。

### IncomeTransaction / ExpenseTransaction を分離した理由

共通の `Transaction` モデルに統合する案も検討したが、`ExpenseTransaction` 固有の
`businessRatioPercent`（事業割合）や `IncomeTransaction` 固有の `isPaid`（入金済み）が
互いに無関係な optional フィールドとして残ってしまい、可読性・安全性が下がると判断した。
共通化によるメリット（一覧クエリの単純化）よりも分離のメリットの方が大きいため分離した。
履歴画面での「すべて」表示は、Services層で2つのモデルをマージして構築する。

### ExpenseCategory を独立したSwiftDataモデルにしなかった理由

カテゴリーは固定の列挙（仕入・消耗品・通信費…）であり、ユーザーが自由に追加/編集する
機能はVer1.0にないため、リレーションを持つモデルにせず `String` enum を直接
`ExpenseTransaction.category` に保存する方式にした（SwiftDataは`Codable`な列挙型を
属性として直接サポートしている）。

### TaxEngineの型（FilingType / BlueReturnDeductionType / BusinessTaxCategory）をアプリ層で再利用

`TaxEngine` はアプリ本体に依存しない（ビルド方向: Atoikura → TaxEngine の一方向のみ）。
一方でアプリ側が `TaxEngine` に依存するのは問題ないため、`UserProfile.filingType` や
`TaxSettings.blueReturnDeduction` / `businessTaxCategory` は `TaxEngine` が定義する型を
そのまま再利用している。同じ概念の型をアプリ層とTaxEngine層で二重定義してマッピング
コードを書くよりも、シンプルで保守しやすいと判断した。
（`ExpenseCategory` は逆にTaxEngineが関知しない純粋なUI/記帳用の概念なのでアプリ層のみに置く。）

### 国民健康保険はユーザー手入力方式にした理由

国民健康保険料は自治体（市区町村）ごとに料率・均等割・上限額が大きく異なり、
所得だけから一意に算出することはできない。無理に自動計算すると実際の金額と大きく
乖離するリスクが高いため、Ver1.0では `TaxSettings.nationalHealthInsuranceAnnualAmount`
にユーザーが自分で調べた年額（または自治体窓口・shirberuサイト等で試算した金額）を
入力してもらう方式にした。未入力時は0円として扱い、ホーム画面・設定画面で
「未設定」であることを明示する（0円を実際の保険料額と誤認させない）。

## 税制データの検証状況（要確認）

2026年分（令和8年分）の税制情報について、一次情報（国税庁等のサイト）への直接アクセスが
ネットワークポリシーでブロックされていたため、Web検索で得られる二次情報（会計ソフト会社の
解説記事等）を突き合わせて実装した。特に以下は**App Store公開前に必ず国税庁の一次資料で
再検証すること**。

- **所得税の基礎控除（令和8年度税制改正分）**: 合計所得金額に応じた多段階の特例控除。
  検索結果間で境界値・金額の記載に食い違いがあり（例: 489万円〜655万円の区分が
  「63万円」なのか「67万円」なのか等）、`TaxRules2026`ではもっとも複数のソースで
  一致していた値を採用しているが未確定。国税庁「令和８年度税制改正による所得税の
  基礎控除の引上げ等について」ページ（`nta.go.jp/users/gensen/2026kiso/`）で確定値を
  確認すること。
- **住民税の基礎控除**: 所得税の基礎控除から一律5万円引いた額として簡略化している。
  実際の令和8年度改正の住民税基礎控除テーブルを個別に確認して補正すること。
- **配偶者控除・扶養控除**: 年齢区分（特定扶養親族・老人扶養親族等）や、令和7年度改正で
  新設された「特定親族特別控除」、配偶者特別控除の所得に応じた段階的な逓減を反映せず、
  一律38万円（所得税）/33万円（住民税）で簡略化している。正確な金額が必要な場合は
  税理士等に確認するようアプリ内で案内している。
- **国民年金保険料**: 令和8年度（2026年4月〜2027年3月）の月額17,920円を通年で使用する
  簡略計算にしている。1〜3月分（令和7年度の料率）は考慮していない。
- **国民健康保険**: 自動計算せずユーザー手入力（上記「主な設計判断」参照）。
- **所得税率の速算表（5%/10%/20%/23%/33%/40%/45%と控除額）**: 長年変更のない安定した
  制度部分であり、今回の税制改正の対象ではないため、確度は高いと判断している。
- **復興特別所得税（所得税額×2.1%）**: 2037年まで継続する安定した制度で、確度は高い。
- **個人事業税（事業主控除290万円、税率3〜5%）**: 業種区分は70種類以上ある正式な法定業種
  区分を簡略化し、4区分（非課税/3%/4%/5%）にまとめている。個人事業税は青色申告特別控除
  を差し引く前の事業所得に対して課税される点に注意（`BusinessTaxCalculator`の入力は
  青色控除前の金額を渡すこと）。
- **青色申告特別控除（10万/55万/65万円）**: 要件の確度は高い。ただし令和8年度税制改正で
  2027年分から55万円区分の廃止・優良電子帳簿による75万円区分の新設が予定されている
  （2026年分にはまだ影響しない見込みだが、`TaxRules2027`実装時に必ず反映すること）。

いずれの項目も、計算結果には必ず「概算」であることを明示し、確定申告・税務判断は
税理士・税務署へ確認するよう促す（免責文言）。

## Phase進行ログ

- Phase1: XcodeGenの`project.yml`、SwiftDataモデル6種、`TaxEngine`パッケージの
  基礎型（`FilingType` / `BlueReturnDeductionType` / `BusinessTaxCategory`）を作成。
  アプリのエントリーポイントと最小限のRootView（オンボーディング/メイン切り替えの
  プレースホルダー）を作成。
- Phase2: オンボーディング4画面（表示名・事業開始年 / 申告方法 / 年間見込み・予備資金 /
  完了）と`OnboardingViewModel`を実装し、`RootView`から接続した。「あとで設定する」は
  どのステップからでも呼べて、未入力項目は安全な初期値のまま保存する。
  `SingletonFetcher`で`UserProfile`/`ReserveSettings`/`AppSettings`をfetch-or-createし、
  RootViewが先に作成した空の`AppSettings`と重複しないようにしている点に注意
  （`OnboardingViewModelTests`で重複が起きないことを確認済み）。
  免責文言は`DisclaimerText`として共通化し、オンボーディング完了画面と将来の設定画面で
  共有する。メインタブ側はまだプレースホルダーのまま（Phase7で本実装）。
- Phase3: 4タブの`MainTabView`（ホーム/履歴/予測/設定、履歴以外はまだプレースホルダー）を
  作成し、`RootView`から接続。売上・経費の追加/編集画面（`IncomeEntryView` /
  `ExpenseEntryView`、金額と日付を最優先表示し「詳細を追加」で展開）、履歴一覧
  （`HistoryView`、すべて/売上/経費セグメント、月別グループ、スワイプ削除＋確認ダイアログ、
  タップで編集）を実装。`IncomeTransaction`に売上の分類用フィールド`category`
  （自由記述、経費と違い定型カテゴリー一覧は設けない）を追加。
  月別グルーピングは`HistoryGrouping`という純粋関数に切り出してユニットテスト済み。
  **重要な修正**: `String`のrawValueを持つenum（`FilingType` /
  `BlueReturnDeductionType` / `BusinessTaxCategory` / `ExpenseCategory` /
  `HistorySegment`）はSwift標準では明示的に`Hashable`を宣言しないと自動適合されない
  （raw valueがあっても暗黙にHashableにはならない）。Picker/`ForEach(id: \.self)`で
  使うため、これらすべてに`Hashable`を明示的に追加した。
- Phase4-6: `TaxEngine`本体（`TaxProfile` / `TaxRuleSet` / `TaxRules2026` /
  `IncomeTaxCalculator` / `ResidentTaxCalculator` / `NationalPensionCalculator` /
  `NationalHealthInsuranceCalculator` / `BusinessTaxCalculator` /
  `TaxCalculationResult` / `TaxEngine`ファサード）を実装し、境界値中心のユニット
  テスト（課税所得0円・1円・税率区分の境界前後、基礎控除の全区分境界、青色申告控除、
  個人事業税の事業主控除境界など）を追加。端数処理（課税所得1,000円未満切り捨て・
  税額100円未満切り捨て）は`TaxRounding`に集約した。
  アプリ側には年間集計（`AnnualSummaryService`）・年間予測（`AnnualForecastService`、
  自動予測と手動設定値を明確に区別）・「今年あと使えるお金」の組み立て
  （`AllowanceCalculator`）をServicesとして追加。

  **設計判断: キャッシュフローと利益をどこまで分離したか** — 要求定義では
  「売上・入金・経費・支払・利益・税金予測・社会保険予測・確保資金・利用可能資金を
  別々に管理する」ことが理想として挙げられていたが、要求定義自身が
  「Ver1.0で複雑になりすぎる場合は『今年の予想手残り』という内部概念を使ってよい」
  と明示的に許容していたため、Ver1.0では**年間の予想利益をベースにした単一の
  『今年あと使えるお金』**に絞った（`AllowanceCalculator`参照）。
  `IncomeTransaction.isPaid`（入金済み/未入金）は履歴画面の表示にのみ使い、
  金額計算には反映していない。実際の入出金（現金残高）ベースの資金繰り管理は
  Ver2以降の拡張候補とし、`isPaid`フィールドはそのための布石として残してある。
- Phase7-9: ホーム画面（`HomeView` / `HomeViewModel`）を「今年あと使えるお金」中心の
  実装に置き換え、「内訳を見る」の開閉、売上/経費/予想利益/税金社会保険/確保資金の表示、
  未入力時の案内文を実装。予測タブ（`ForecastView`）で自動予測（実績ベースの単純年間
  換算）と手動設定を切り替え可能にし、`TaxSettings.manualRevenueForecast` /
  `manualExpenseForecast` に即時保存する。設定タブ（`SettingsView` /
  `SettingsViewModel`）でプロフィール・対象年度・申告方法・青色申告特別控除・
  都道府県・生年・扶養・配偶者・社会保険・個人事業税の業種区分・予備資金を管理できる
  ようにした。都道府県用に`Prefecture`（47都道府県+未設定）を追加。
  `TaxSettings`に`prefecture`・`birthYear`を追加（Ver1.0の税計算では未使用、
  Ver2以降の拡張・参考情報として保持）。

  **設計判断: 対象年度の切り替え** — 設定画面で対象年度を変更すると、その年度の
  `TaxSettings`（無ければ初期値）を読み込み直す（`SettingsViewModel.selectYear`）。
  年度に依存しないプロフィール・予備資金はそのまま維持する。年度切り替え時に
  読み込み直したフィールドの変更検知で自動保存が再度走る（同じ値を書き戻すだけの
  冗長な保存が発生するが、データ破損リスクは無いため許容している）。
- Phase10（進行中）: `project.yml`の`PRODUCT_NAME`を「あといくら」に設定していたのを
  削除した。`PRODUCT_NAME`はSwiftのモジュール名（`PRODUCT_MODULE_NAME`、デフォルトは
  `$(PRODUCT_NAME:c99extidentifier)`）にも影響し、日本語文字列を指定すると
  `@testable import Atoikura`（テストコード側でモジュール名を`Atoikura`決め打ちしている）
  が壊れるリスクがあったため。ホーム画面に表示される日本語のアプリ名は、代わりに
  Info.plistの`CFBundleDisplayName`（既に「あといくら」を設定済み）だけで十分。

## Ver1.0 完成条件チェックリスト（現状）

ユーザーが定義した完成条件に対する現状。**「実機/シミュレータで確認」欄がNoの項目は、
Xcode/Swiftツールチェーンの無い環境で実装されたため未検証。macOSでXcodeを使える環境に
引き継いだら、最初に必ずこれらを確認すること。**

| 項目 | 実装状況 | 実機/シミュレータで確認 |
|---|---|---|
| オンボーディング→ホーム到達 | 実装済み | No |
| 売上・経費の登録 | 実装済み | No |
| ホームへの反映（売上・経費・利益） | 実装済み（`@Query`により自動更新） | No |
| 予想税金等の表示 | 実装済み（TaxEngine連携） | No |
| 「今年あと使えるお金」の更新 | 実装済み | No |
| 再起動後もデータが残る | 実装済み（`isStoredInMemoryOnly: false`） | No |
| データの編集・削除 | 実装済み | No |
| 税計算のユニットテスト | テストコードは実装済み（境界値中心） | **No（`swift test`未実行）** |
| 主要画面でクラッシュしない | 強制アンラップ排除・防御的な初期値で設計 | No |
| ダークモード対応 | セマンティックカラーのみ使用（確認済み、grepで検証） | No |
| Dynamic Type対応 | ホーム画面の巨大数字は`@ScaledMetric`で対応 | No |
| 小型iPhoneでのレイアウト | ScrollView/Form中心の可変レイアウトで設計 | No |

**次にXcodeが使える人/エージェントがやるべきこと（優先順）:**
1. `cd TaxEngine && swift test` でTaxEngineの境界値テストを実行し、全て green にする。
2. `xcodegen generate` して `Atoikura.xcodeproj` を開き、`⌘B` でビルドが通ることを確認する
   （型エラー・API誤用がないか、この時点で初めて機械的に検証できる）。
3. `⌘U` でAtoikuraTestsも含めて全テストを実行する。
4. iPhone SE（小型）とiPhone Pro Max（大型）のシミュレータでオンボーディング→
   売上/経費登録→ホーム確認までの一連の操作を手動で行う。
5. ダークモード・Dynamic Type（設定 > アクセシビリティ > さらに大きな文字）を
   オンにして崩れがないか確認する。
6. 実際のAppIcon画像（1024×1024のPNG）を`Atoikura/Resources/Assets.xcassets/AppIcon.appiconset`
   に追加する。

## 静的レビューで見つかった不具合の修正記録

ビルドできない環境での実装が続いたため、別のエージェントに読み取り専用の静的レビューを
依頼した（型・import・SwiftData/SwiftUI API・境界値ロジックを中心に39ファイルを確認）。

見つかった不具合: `ForecastView`は初回表示時に一度だけ`TaxSettings`の手動予測値を
`@State`へ読み込み、以後は読み込み直さない設計だった（`hasLoadedInitialValues`フラグで
ガード）。そのため、設定タブで対象年度を変更してから予測タブに戻ると、画面上の
「手動で設定する」トグルや金額が**古い年度の値のまま**残ってしまい、そこでユーザーが
何か操作すると、古い年度の手動予測値が新しい年度の`TaxSettings`に誤って書き込まれる
可能性があった。

対応: `hasLoadedInitialValues: Bool` を `loadedYear: Int?` に変更し、`year`
（対象年度、`AppSettings.selectedYear`由来）と食い違ったら読み込み直すように修正
（`loadValuesIfYearChanged()`、`.onChange(of: year)`を追加）。`save()`も
`loadedYear == year` の場合のみ書き込むようにし、読み込み直し中の書き込みを防いでいる。
他の指摘事項は無かった（型エラー・import漏れ・force unwrap・SwiftData API誤用など）。
