import SwiftUI
import SwiftData

/// アプリのルート。オンボーディング未完了ならオンボーディングを、完了済みならメインタブを表示する。
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettingsList: [AppSettings]

    var body: some View {
        Group {
            if let appSettings = appSettingsList.first, appSettings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .onAppear(perform: ensureAppSettingsExists)
    }

    private func ensureAppSettingsExists() {
        guard appSettingsList.isEmpty else { return }
        modelContext.insert(AppSettings())
    }
}

#Preview {
    RootView()
        .modelContainer(for: [
            UserProfile.self,
            IncomeTransaction.self,
            ExpenseTransaction.self,
            TaxSettings.self,
            ReserveSettings.self,
            AppSettings.self
        ], inMemory: true)
}
