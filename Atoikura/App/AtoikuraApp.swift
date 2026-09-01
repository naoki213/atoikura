import SwiftUI
import SwiftData

@main
struct AtoikuraApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            UserProfile.self,
            IncomeTransaction.self,
            ExpenseTransaction.self,
            TaxSettings.self,
            ReserveSettings.self,
            AppSettings.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftDataのModelContainer初期化に失敗しました: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
