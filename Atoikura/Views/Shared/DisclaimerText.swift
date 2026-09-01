import SwiftUI

/// 免責事項。オンボーディング完了画面と設定画面の両方で表示する共通コンポーネント。
struct DisclaimerText: View {
    var body: some View {
        Text("表示される税額・社会保険料はあくまで概算です。実際の金額を保証するものではありません。確定申告や税務上の判断については、税務署や税理士にご確認ください。")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
