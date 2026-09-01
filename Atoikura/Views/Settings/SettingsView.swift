import SwiftUI

/// 設定画面。Phase9で対象年度・申告方法・控除・社会保険等の設定項目を実装する。
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("設定画面は準備中です")
                        .foregroundStyle(.secondary)
                }
                Section {
                    DisclaimerText()
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
}
