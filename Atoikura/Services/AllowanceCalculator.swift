import Foundation
import TaxEngine

/// 「今年あと使えるお金」の内訳。ホーム画面はこの結果をそのまま表示する。
struct AllowanceBreakdown: Equatable {
    let year: Int
    let revenueForecast: Decimal
    let expenseForecast: Decimal

    /// 予想利益（売上予測 − 経費予測）。マイナスになることもある。
    let projectedProfit: Decimal

    /// 税金・社会保険として確保しておく金額（概算）。
    let taxAndSocialInsuranceReserve: Decimal
    let businessReserve: Decimal
    let otherReserve: Decimal

    /// 今年あと使えるお金（予想利益 − 税金社会保険 − 確保資金）。マイナスは赤字・不足のサイン。
    let remainingAllowance: Decimal

    let taxCalculationResult: TaxCalculationResult
}

/// 年間予測・税計算結果・確保資金設定から「今年あと使えるお金」を組み立てる。
///
/// 会計上の利益とキャッシュフロー（実際の入出金）を混同しないよう、Ver1.0では
/// 「年間の予想利益をベースにした、あと使えるお金」という単一の考え方に絞っている
/// （入金済み/未入金の区別は履歴の表示にのみ使い、この計算には使わない）。
enum AllowanceCalculator {
    static func calculate(
        forecast: AnnualForecast,
        userProfile: UserProfile,
        taxSettings: TaxSettings,
        reserveSettings: ReserveSettings
    ) -> AllowanceBreakdown {
        let projectedProfit = forecast.revenueForecast - forecast.expenseForecast

        let taxProfile = TaxProfile(
            year: forecast.year,
            businessProfit: max(0, projectedProfit),
            filingType: userProfile.filingType,
            blueReturnDeduction: taxSettings.blueReturnDeduction,
            dependentsCount: taxSettings.dependentsCount,
            hasSpouse: taxSettings.hasSpouse,
            isNationalPensionEnrolled: taxSettings.isNationalPensionEnrolled,
            nationalHealthInsuranceAnnualAmount: taxSettings.nationalHealthInsuranceAnnualAmount,
            hasSetNationalHealthInsuranceAmount: taxSettings.hasSetNationalHealthInsuranceAmount,
            businessTaxCategory: taxSettings.businessTaxCategory
        )

        let taxResult = TaxEngine.calculate(profile: taxProfile)
        let reserveTotal = reserveSettings.businessReserveAmount + reserveSettings.otherReserveAmount
        let remainingAllowance = projectedProfit - taxResult.totalAmount - reserveTotal

        return AllowanceBreakdown(
            year: forecast.year,
            revenueForecast: forecast.revenueForecast,
            expenseForecast: forecast.expenseForecast,
            projectedProfit: projectedProfit,
            taxAndSocialInsuranceReserve: taxResult.totalAmount,
            businessReserve: reserveSettings.businessReserveAmount,
            otherReserve: reserveSettings.otherReserveAmount,
            remainingAllowance: remainingAllowance,
            taxCalculationResult: taxResult
        )
    }
}
