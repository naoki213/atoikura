import XCTest
import SwiftData
@testable import Atoikura

final class OnboardingViewModelTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            UserProfile.self,
            IncomeTransaction.self,
            ExpenseTransaction.self,
            TaxSettings.self,
            ReserveSettings.self,
            AppSettings.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    /// RootViewが起動時に空のAppSettingsを1件作成した後にオンボーディングを完了しても、
    /// AppSettingsが重複作成されないことを確認する。
    func testCompleteOnboardingDoesNotDuplicateAppSettings() throws {
        let context = try makeContext()
        context.insert(AppSettings())
        try context.save()

        let viewModel = OnboardingViewModel(currentYear: 2026)
        viewModel.displayName = "山田太郎"
        viewModel.businessStartYear = 2020
        viewModel.annualRevenueForecast = 6_000_000
        viewModel.businessReserveAmount = 500_000

        try viewModel.completeOnboarding(context: context)

        let appSettingsList = try context.fetch(FetchDescriptor<AppSettings>())
        XCTAssertEqual(appSettingsList.count, 1)
        XCTAssertTrue(appSettingsList[0].hasCompletedOnboarding)
        XCTAssertTrue(appSettingsList[0].hasAcknowledgedDisclaimer)
        XCTAssertEqual(appSettingsList[0].selectedYear, 2026)
    }

    func testCompleteOnboardingPersistsProfileAndForecastAndReserve() throws {
        let context = try makeContext()

        let viewModel = OnboardingViewModel(currentYear: 2026)
        viewModel.displayName = "山田太郎"
        viewModel.businessStartYear = 2020
        viewModel.annualRevenueForecast = 6_000_000
        viewModel.annualExpenseForecast = 1_500_000
        viewModel.businessReserveAmount = 500_000

        try viewModel.completeOnboarding(context: context)

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles[0].displayName, "山田太郎")
        XCTAssertEqual(profiles[0].businessStartYear, 2020)

        let taxSettingsList = try context.fetch(FetchDescriptor<TaxSettings>())
        XCTAssertEqual(taxSettingsList.count, 1)
        XCTAssertEqual(taxSettingsList[0].manualRevenueForecast, 6_000_000)
        XCTAssertEqual(taxSettingsList[0].manualExpenseForecast, 1_500_000)

        let reserveSettingsList = try context.fetch(FetchDescriptor<ReserveSettings>())
        XCTAssertEqual(reserveSettingsList.count, 1)
        XCTAssertEqual(reserveSettingsList[0].businessReserveAmount, 500_000)
    }

    /// 「あとで設定する」で未入力のまま完了しても、安全な初期値で保存できることを確認する。
    func testCompleteOnboardingWithoutOptionalInputsUsesSafeDefaults() throws {
        let context = try makeContext()
        let viewModel = OnboardingViewModel(currentYear: 2026)

        try viewModel.completeOnboarding(context: context)

        let reserveSettingsList = try context.fetch(FetchDescriptor<ReserveSettings>())
        XCTAssertEqual(reserveSettingsList.first?.businessReserveAmount, 0)

        let taxSettingsList = try context.fetch(FetchDescriptor<TaxSettings>())
        XCTAssertNil(taxSettingsList.first?.manualRevenueForecast)
        XCTAssertNil(taxSettingsList.first?.manualExpenseForecast)
    }
}
