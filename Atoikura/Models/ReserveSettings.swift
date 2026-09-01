import Foundation
import SwiftData

/// 事業用に残しておきたい予備資金の設定。アプリ内には常に1件のみ存在する。
@Model
final class ReserveSettings {
    /// 事業用に残しておきたい予備資金。
    var businessReserveAmount: Decimal

    /// その他確保しておきたい資金（納税用の別枠など、任意）。
    var otherReserveAmount: Decimal

    init(businessReserveAmount: Decimal = 0, otherReserveAmount: Decimal = 0) {
        self.businessReserveAmount = businessReserveAmount
        self.otherReserveAmount = otherReserveAmount
    }
}
