import Foundation
import Observation
import SwiftData
import TaxEngine

/// 設定画面の状態。対象年度を切り替えると、その年度のTaxSettingsを読み込み直す。
@Observable
final class SettingsViewModel {
    // プロフィール（年度に依存しない）
    var displayName: String = ""
    var businessStartYear: Int = Calendar.current.component(.year, from: .now)
    var filingType: FilingType = .blue

    // 対象年度
    private(set) var selectedYear: Int = Calendar.current.component(.year, from: .now)

    // 年度ごとの税計算用プロフィール
    var blueReturnDeduction: BlueReturnDeductionType = .notEligible
    var prefecture: Prefecture = .unspecified
    var birthYear: Int?
    var dependentsCount: Int = 0
    var hasSpouse: Bool = false
    var isNationalPensionEnrolled: Bool = true
    var hasSetNationalHealthInsuranceAmount: Bool = false
    var nationalHealthInsuranceAnnualAmount: Decimal?
    var businessTaxCategory: BusinessTaxCategory = .rate5Percent

    // 予備資金（年度に依存しない）
    var businessReserveAmount: Decimal?
    var otherReserveAmount: Decimal?

    private(set) var isLoaded = false

    func load(
        userProfile: UserProfile?,
        appSettings: AppSettings?,
        taxSettings: TaxSettings?,
        reserveSettings: ReserveSettings?
    ) {
        guard !isLoaded else { return }

        if let userProfile {
            displayName = userProfile.displayName
            businessStartYear = userProfile.businessStartYear
            filingType = userProfile.filingType
        }
        selectedYear = appSettings?.selectedYear ?? selectedYear
        applyTaxSettings(taxSettings ?? TaxSettings(year: selectedYear))
        if let reserveSettings {
            businessReserveAmount = reserveSettings.businessReserveAmount
            otherReserveAmount = reserveSettings.otherReserveAmount
        }

        isLoaded = true
    }

    /// 対象年度を切り替え、その年度のTaxSettings（無ければ初期値）を読み込み直す。
    /// プロフィール・予備資金は年度に依存しないため変更しない。
    func selectYear(_ newYear: Int, taxSettings: TaxSettings?, context: ModelContext) {
        selectedYear = newYear
        applyTaxSettings(taxSettings ?? TaxSettings(year: newYear))

        let appSettings = SingletonFetcher.fetchOrCreate(AppSettings.self, in: context) { AppSettings() }
        appSettings.selectedYear = newYear
        try? context.save()
    }

    private func applyTaxSettings(_ taxSettings: TaxSettings) {
        blueReturnDeduction = taxSettings.blueReturnDeduction
        prefecture = taxSettings.prefecture
        birthYear = taxSettings.birthYear
        dependentsCount = taxSettings.dependentsCount
        hasSpouse = taxSettings.hasSpouse
        isNationalPensionEnrolled = taxSettings.isNationalPensionEnrolled
        hasSetNationalHealthInsuranceAmount = taxSettings.hasSetNationalHealthInsuranceAmount
        nationalHealthInsuranceAnnualAmount = taxSettings.hasSetNationalHealthInsuranceAmount
            ? taxSettings.nationalHealthInsuranceAnnualAmount
            : nil
        businessTaxCategory = taxSettings.businessTaxCategory
    }

    /// プロフィール・現在の年度の税設定・予備資金を保存する。
    /// 対象年度そのものの変更は `selectYear` が担うため、ここでは触らない。
    func save(context: ModelContext) throws {
        guard isLoaded else { return }

        let profile = SingletonFetcher.fetchOrCreate(UserProfile.self, in: context) { UserProfile() }
        profile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.businessStartYear = businessStartYear
        profile.filingType = filingType

        let year = selectedYear
        let existingTaxSettings = try context.fetch(
            FetchDescriptor<TaxSettings>(predicate: #Predicate { $0.year == year })
        ).first
        let taxSettings: TaxSettings
        if let existingTaxSettings {
            taxSettings = existingTaxSettings
        } else {
            taxSettings = TaxSettings(year: year)
            context.insert(taxSettings)
        }
        taxSettings.blueReturnDeduction = blueReturnDeduction
        taxSettings.prefecture = prefecture
        taxSettings.birthYear = birthYear
        taxSettings.dependentsCount = dependentsCount
        taxSettings.hasSpouse = hasSpouse
        taxSettings.isNationalPensionEnrolled = isNationalPensionEnrolled
        taxSettings.hasSetNationalHealthInsuranceAmount = hasSetNationalHealthInsuranceAmount
        taxSettings.nationalHealthInsuranceAnnualAmount = hasSetNationalHealthInsuranceAmount
            ? (nationalHealthInsuranceAnnualAmount ?? 0)
            : 0
        taxSettings.businessTaxCategory = businessTaxCategory

        let reserveSettings = SingletonFetcher.fetchOrCreate(ReserveSettings.self, in: context) { ReserveSettings() }
        reserveSettings.businessReserveAmount = businessReserveAmount ?? 0
        reserveSettings.otherReserveAmount = otherReserveAmount ?? 0

        try context.save()
    }
}
