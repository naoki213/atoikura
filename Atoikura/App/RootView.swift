import SwiftUI
import SwiftData

/// アプリのルート。オンボーディング未完了ならオンボーディングを、完了済みならメインタブを表示する。
///
/// オンボーディングの実画面はPhase2で実装するため、現時点では暫定のプレースホルダーを表示する。
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettingsList: [AppSettings]

    var body: some View {
        Group {
            if let appSettings = appSettingsList.first {
                if appSettings.hasCompletedOnboarding {
                    MainTabPlaceholderView()
                } else {
                    OnboardingPlaceholderView()
                }
            } else {
                OnboardingPlaceholderView()
            }
        }
        .onAppear(perform: ensureAppSettingsExists)
    }

    private func ensureAppSettingsExists() {
        guard appSettingsList.isEmpty else { return }
        modelContext.insert(AppSettings())
    }
}

/// Phase2でオンボーディング画面に置き換える暫定表示。
private struct OnboardingPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "yensign.circle")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            Text("あといくら")
                .font(.title.bold())
            Text("オンボーディングは準備中です")
                .foregroundStyle(.secondary)
        }
    }
}

/// Phase7以降でホームタブなどに置き換える暫定表示。
private struct MainTabPlaceholderView: View {
    var body: some View {
        Text("メイン画面は準備中です")
            .foregroundStyle(.secondary)
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
