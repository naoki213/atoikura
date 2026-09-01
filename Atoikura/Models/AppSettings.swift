import Foundation
import SwiftData

/// アプリ全体の状態。アプリ内には常に1件のみ存在する（シングルトン的に扱う）。
@Model
final class AppSettings {
    var hasCompletedOnboarding: Bool
    var hasAcknowledgedDisclaimer: Bool
    var selectedYear: Int

    init(
        hasCompletedOnboarding: Bool = false,
        hasAcknowledgedDisclaimer: Bool = false,
        selectedYear: Int = Calendar.current.component(.year, from: .now)
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasAcknowledgedDisclaimer = hasAcknowledgedDisclaimer
        self.selectedYear = selectedYear
    }
}
