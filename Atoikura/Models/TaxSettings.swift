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
