import Foundation

/// 履歴一覧の月別セクション。
struct HistorySection: Identifiable {
    let id: Date
    let title: String
    let items: [HistoryItem]
}

/// 履歴項目を月別にグループ化する純粋関数。Viewからロジックを分離してテスト可能にしている。
enum HistoryGrouping {
    static func monthlySections(
        items: [HistoryItem],
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "ja_JP")
    ) -> [HistorySection] {
        let grouped = Dictionary(grouping: items) { item in
            calendar.dateInterval(of: .month, for: item.date)?.start ?? item.date
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy年M月"

        return grouped.keys
            .sorted(by: >)
            .map { monthStart in
                let sortedItems = (grouped[monthStart] ?? []).sorted { $0.date > $1.date }
                return HistorySection(
                    id: monthStart,
                    title: formatter.string(from: monthStart),
                    items: sortedItems
                )
            }
    }
}
