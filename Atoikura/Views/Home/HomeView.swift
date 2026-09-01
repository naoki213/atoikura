import SwiftUI

/// ホーム画面。Phase7で「今年あと使えるお金」を中心とした本実装に置き換える。
struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "yensign.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                Text("ホーム画面は準備中です")
                    .foregroundStyle(.secondary)
                Text("履歴タブから売上・経費を登録できます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("ホーム")
        }
    }
}

#Preview {
    HomeView()
}
