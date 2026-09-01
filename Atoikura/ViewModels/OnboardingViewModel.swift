import Foundation
import Observation
import SwiftData
import TaxEngine

/// オンボーディング入力中の下書きを保持し、完了時にSwiftDataへ保存する。
@Observable
final class OnboardingViewModel {
    var displayName: String = ""
    var businessStartYear: Int
    var filingType: FilingType = .blue
    var annualRevenueForecast: Decimal?
    var annualExpenseForecast: Decimal?
    var businessReserveAmount: Decimal?

    private let currentYear: Int

    init(currentYear: Int = Calendar.current.component(.year, from: .now)) {
        self.currentYear = currentYear
        self.businessStartYear = currentYear
    }

    var businessStartYearRange: ClosedRange<Int> {
        (currentYear - 30)...currentYear
    }

    /// 入力内容をSwiftDataへ保存し、オンボーディングを完了とする。
    /// 「あとで設定する」で途中の画面から呼ばれた場合、未入力の項目は初期値のまま保存される。
    func completeOnboarding(context: ModelContext) throws {
        let profile = SingletonFetcher.fetchOrCreate(UserProfile.self, in: context) { UserProfile() }
        profile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.businessStartYear = businessStartYear
        profile.filingType = filingType

        let year = currentYear
        let existingTaxSettings = try context.fetch(
            FetchDescriptor<TaxSettings>(predicate: #Predicate { $0.year == year })
        ).first
        if let existingTaxSettings {
            existingTaxSettings.manualRevenueForecast = annualRevenueForecast
            existingTaxSettings.manualExpenseForecast = annualExpenseForecast
        } else {
            context.insert(
                TaxSettings(
                    year: year,
                    manualRevenueForecast: annualRevenueForecast,
                    manualExpenseForecast: annualExpenseForecast
                )
            )
        }

        let reserveSettings = SingletonFetcher.fetchOrCreate(ReserveSettings.self, in: context) { ReserveSettings() }
        reserveSettings.businessReserveAmount = businessReserveAmount ?? 0

        let appSettings = SingletonFetcher.fetchOrCreate(AppSettings.self, in: context) { AppSettings() }
        appSettings.hasCompletedOnboarding = true
        appSettings.hasAcknowledgedDisclaimer = true
        appSettings.selectedYear = year

        try context.save()
    }
}
