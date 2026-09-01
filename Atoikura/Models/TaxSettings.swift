import Foundation
import SwiftData
import TaxEngine

/// 年度ごとの税計算用プロフィール設定。
///
/// `year` をキーに1年度につき1件だけ存在する想定。
/// 詳細設定を行っていなくてもアプリが使えるよう、すべての項目に安全な初期値を持たせている。
@Model
final class TaxSettings {
    @Attribute(.unique) var year: Int

    var blueReturnDeduction: BlueReturnDeductionType

    /// 都道府県。Ver1.0の税計算では直接使用しないが、Ver2以降の国民健康保険の
    /// 地域別概算などに備えて保持しておく（設定画面のみで使用）。
    var prefecture: Prefecture

    /// 生年。年齢を用いた控除区分の判定はVer1.0では行わない簡略化のための参考情報。
    var birthYear: Int?

    var dependentsCount: Int
    var hasSpouse: Bool

    var isNationalPensionEnrolled: Bool

    /// 国民健康保険の年額（自治体差が大きいため自動計算せずユーザーが手入力する）。
    /// 未入力の場合は 0 として扱い、ホーム画面では「未設定」であることを案内する。
    var nationalHealthInsuranceAnnualAmount: Decimal
    var hasSetNationalHealthInsuranceAmount: Bool

    var businessTaxCategory: BusinessTaxCategory

    /// 年間売上・経費の手動予測値。nil の場合は実績ベースの自動予測を使う。
    var manualRevenueForecast: Decimal?
    var manualExpenseForecast: Decimal?

    init(
        year: Int,
        blueReturnDeduction: BlueReturnDeductionType = .notEligible,
        prefecture: Prefecture = .unspecified,
        birthYear: Int? = nil,
        dependentsCount: Int = 0,
        hasSpouse: Bool = false,
        isNationalPensionEnrolled: Bool = true,
        nationalHealthInsuranceAnnualAmount: Decimal = 0,
        hasSetNationalHealthInsuranceAmount: Bool = false,
        businessTaxCategory: BusinessTaxCategory = .rate5Percent,
        manualRevenueForecast: Decimal? = nil,
        manualExpenseForecast: Decimal? = nil
    ) {
        self.year = year
        self.blueReturnDeduction = blueReturnDeduction
        self.prefecture = prefecture
        self.birthYear = birthYear
        self.dependentsCount = dependentsCount
        self.hasSpouse = hasSpouse
        self.isNationalPensionEnrolled = isNationalPensionEnrolled
        self.nationalHealthInsuranceAnnualAmount = nationalHealthInsuranceAnnualAmount
        self.hasSetNationalHealthInsuranceAmount = hasSetNationalHealthInsuranceAmount
        self.businessTaxCategory = businessTaxCategory
        self.manualRevenueForecast = manualRevenueForecast
        self.manualExpenseForecast = manualExpenseForecast
    }
}
