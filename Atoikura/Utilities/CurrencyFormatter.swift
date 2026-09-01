import Foundation

/// 金額表示用のフォーマッタ。アプリ全体で表示形式を統一するために使う。
enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// 例: "¥3,420,000"
    static func string(from value: Decimal) -> String {
        formatter.string(from: value as NSDecimalNumber) ?? "¥\(value)"
    }

    static func string(from value: Decimal?) -> String {
        guard let value else { return "¥0" }
        return string(from: value)
    }
}
