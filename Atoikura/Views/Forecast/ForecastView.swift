import SwiftUI

/// 予測画面。Phase8で年間予測（自動予測・手動修正）を実装する。
struct ForecastView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                Text("予測画面は準備中です")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("予測")
        }
    }
}

#Preview {
    ForecastView()
}
