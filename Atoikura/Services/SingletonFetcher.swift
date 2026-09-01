import Foundation
import SwiftData

/// `UserProfile` / `AppSettings` / `ReserveSettings` のように
/// アプリ内に常に1件だけ存在するモデルを取得・なければ作成するためのヘルパー。
enum SingletonFetcher {
    static func fetchOrCreate<T: PersistentModel>(
        _ type: T.Type,
        in context: ModelContext,
        makeDefault: () -> T
    ) -> T {
        let descriptor = FetchDescriptor<T>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = makeDefault()
        context.insert(created)
        return created
    }
}
