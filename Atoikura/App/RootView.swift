import SwiftUI
import SwiftData

/// アプリのルート。オンボーディング未完了ならオンボーディングを、完了済みならメインタブを表示する。
///
/// メインタブ（ホーム/履歴/予測/設定）の実画面はPhase3以降で実装するため、
/// 現時点では暫定のプレースホルダーを表示する。
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettingsList: [AppSettings]

    var body: some View {
        Group {
            if let appSettings = appSettingsList.first, appSettings.hasCompletedOnboarding {
                MainTabPlaceholderView()
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

/// Phase7以降でホームタブなどに置き換える暫定表示。
private struct MainTabPlaceholderView: View {
    @Query private var userProfiles: [UserProfile]

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            Text("設定が保存されました")
                .font(.title3.bold())
            if let name = userProfiles.first?.displayName, !name.isEmpty {
                Text("ようこそ、\(name)さん")
                    .foregroundStyle(.secondary)
            }
            Text("メインタブ（ホーム/履歴/予測/設定）は準備中です")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
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
