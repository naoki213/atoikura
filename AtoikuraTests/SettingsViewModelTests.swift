import XCTest
import SwiftData
import TaxEngine
@testable import Atoikura

final class SettingsViewModelTests: XCTestCase {
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

    func testLoadPopulatesFieldsFromExistingModels() throws {
        let context = try makeContext()
        let profile = UserProfile(displayName: "山田太郎", businessStartYear: 2020, filingType: .blue)
        let taxSettings = TaxSettings(
            year: 2026,
            blueReturnDeduction: .doubleEntryElectronicFiling,
            dependentsCount: 2,
            hasSpouse: true
        )
        context.insert(profile)
        context.insert(taxSettings)
        try context.save()

        let viewModel = SettingsViewModel()
        viewModel.load(userProfile: profile, appSettings: nil, taxSettings: taxSettings, reserveSettings: nil)

        XCTAssertEqual(viewModel.displayName, "山田太郎")
        XCTAssertEqual(viewModel.dependentsCount, 2)
        XCTAssertTrue(viewModel.hasSpouse)
        XCTAssertEqual(viewModel.blueReturnDeduction, .doubleEntryElectronicFiling)
    }

    func testSelectYearSwitchesTaxSettingsWithoutAffectingProfile() throws {
        let context = try makeContext()
        let taxSettings2026 = TaxSettings(year: 2026, dependentsCount: 1)
        context.insert(taxSettings2026)
        try context.save()

        let viewModel = SettingsViewModel()
        viewModel.load(userProfile: nil, appSettings: nil, taxSettings: taxSettings2026, reserveSettings: nil)
        viewModel.displayName = "屋号A"

        // 2027年にはまだTaxSettingsが無い -> 初期値に切り替わるはず
        viewModel.selectYear(2027, taxSettings: nil, context: context)

        XCTAssertEqual(viewModel.selectedYear, 2027)
        XCTAssertEqual(viewModel.dependentsCount, 0)
        // 年度に依存しないプロフィールは維持される
        XCTAssertEqual(viewModel.displayName, "屋号A")
    }

    func testSaveWritesTaxSettingsForCurrentlySelectedYearOnly() throws {
        let context = try makeContext()
        let viewModel = SettingsViewModel()
        viewModel.load(userProfile: nil, appSettings: nil, taxSettings: TaxSettings(year: 2026), reserveSettings: nil)

        viewModel.dependentsCount = 3
        try viewModel.save(context: context)

        let saved = try context.fetch(FetchDescriptor<TaxSettings>(predicate: #Predicate { $0.year == 2026 }))
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.dependentsCount, 3)
    }

    func testNationalHealthInsuranceAmountIsClearedWhenToggleIsOff() throws {
        let context = try makeContext()
        let viewModel = SettingsViewModel()
        viewModel.load(userProfile: nil, appSettings: nil, taxSettings: TaxSettings(year: 2026), reserveSettings: nil)

        viewModel.hasSetNationalHealthInsuranceAmount = false
        viewModel.nationalHealthInsuranceAnnualAmount = 300_000
        try viewModel.save(context: context)

        let saved = try context.fetch(FetchDescriptor<TaxSettings>(predicate: #Predicate { $0.year == 2026 })).first
        XCTAssertEqual(saved?.nationalHealthInsuranceAnnualAmount, 0)
        XCTAssertFalse(saved?.hasSetNationalHealthInsuranceAmount ?? true)
    }
}
