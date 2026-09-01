import Foundation

/// 年間の売上・経費予測。自動予測（実績ベースの単純年間換算）と手動設定値を区別する。
struct AnnualForecast: Equatable {
    let year: Int
    let revenueForecast: Decimal
    let expenseForecast: Decimal
    let isRevenueManual: Bool
    let isExpenseManual: Bool
}

enum AnnualForecastService {
    /// 手動設定値があればそれを優先し、無ければ実績ベースの単純な年間換算（実績 ÷ 経過月数 × 12）を使う。
    static func forecast(
        actuals: AnnualActuals,
        manualRevenueForecast: Decimal?,
        manualExpenseForecast: Decimal?
    ) -> AnnualForecast {
        AnnualForecast(
            year: actuals.year,
            revenueForecast: manualRevenueForecast ?? projectedAnnualAmount(actuals: actuals, actual: actuals.totalRevenue),
            expenseForecast: manualExpenseForecast ?? projectedAnnualAmount(actuals: actuals, actual: actuals.totalExpense),
            isRevenueManual: manualRevenueForecast != nil,
            isExpenseManual: manualExpenseForecast != nil
        )
    }

    private static func projectedAnnualAmount(actuals: AnnualActuals, actual: Decimal) -> Decimal {
        guard actuals.elapsedMonths > 0 else { return actual }
        let clampedMonths = min(actuals.elapsedMonths, 12)
        return actual / Decimal(clampedMonths) * 12
    }
}
