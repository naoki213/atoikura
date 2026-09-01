import SwiftUI

/// オンボーディング完了後のメイン画面。原則4タブ構成。
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }

            HistoryView()
                .tabItem { Label("履歴", systemImage: "list.bullet") }

            ForecastView()
                .tabItem { Label("予測", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            UserProfile.self,
            IncomeTransaction.self,
            ExpenseTransaction.self,
            TaxSettings.self,
            ReserveSettings.self,
            AppSettings.self
        ], inMemory: true)
}
