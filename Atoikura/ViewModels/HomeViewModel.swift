import Foundation

/// ホーム画面の表示用データ。SwiftDataから取得した生データをServices経由で
/// 「今年あと使えるお金」の内訳にまとめる。
struct HomeViewModel {
    let year: Int
    let breakdown: AllowanceBreakdown
    let hasAnyTransaction: Bool

    static func build(
        year: Int,
        incomeTransactions: [IncomeTransaction],
        expenseTransactions: [ExpenseTransaction],
        userProfile: UserProfile?,
        taxSettings: TaxSettings?,
        reserveSettings: ReserveSettings?
    ) -> HomeViewModel {
        // 詳細設定を行っていなくてもアプリが使えるよう、欠けている設定は安全な初期値で補う。
        let profile = userProfile ?? UserProfile()
        let settings = taxSettings ?? TaxSettings(year: year)
        let reserve = reserveSettings ?? ReserveSettings()

        let actuals = AnnualSummaryService.actuals(
            year: year,
            incomeTransactions: incomeTransactions,
            expenseTransactions: expenseTransactions
        )
        let forecast = AnnualForecastService.forecast(
            actuals: actuals,
            manualRevenueForecast: settings.manualRevenueForecast,
            manualExpenseForecast: settings.manualExpenseForecast
        )
        let breakdown = AllowanceCalculator.calculate(
            forecast: forecast,
            userProfile: profile,
            taxSettings: settings,
            reserveSettings: reserve
        )

        return HomeViewModel(
            year: year,
            breakdown: breakdown,
            hasAnyTransaction: !incomeTransactions.isEmpty || !expenseTransactions.isEmpty
        )
    }
}
