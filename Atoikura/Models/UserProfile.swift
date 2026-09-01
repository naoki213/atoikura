import Foundation
import SwiftData
import TaxEngine

/// アプリ利用者の基本プロフィール。アプリ内には常に1件のみ存在する（シングルトン的に扱う）。
@Model
final class UserProfile {
    var displayName: String
    var businessStartYear: Int
    var filingType: FilingType
    var createdAt: Date

    init(
        displayName: String = "",
        businessStartYear: Int = Calendar.current.component(.year, from: .now),
        filingType: FilingType = .blue,
        createdAt: Date = .now
    ) {
        self.displayName = displayName
        self.businessStartYear = businessStartYear
        self.filingType = filingType
        self.createdAt = createdAt
    }
}
