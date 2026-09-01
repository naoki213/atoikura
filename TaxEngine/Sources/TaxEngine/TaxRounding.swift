import Foundation

/// 日本の税額計算で一般的な端数処理（切り捨て）をまとめたユーティリティ。
enum TaxRounding {
    /// 課税所得の端数処理（1,000円未満切り捨て）。
    static func taxableIncome(_ value: Decimal) -> Decimal {
        flooring(value, toMultipleOf: 1_000)
    }

    /// 税額の端数処理（100円未満切り捨て）。
    static func taxAmount(_ value: Decimal) -> Decimal {
        flooring(value, toMultipleOf: 100)
    }

    private static func flooring(_ value: Decimal, toMultipleOf unit: Decimal) -> Decimal {
        guard value > 0 else { return 0 }

        let handler = NSDecimalNumberHandler(
            roundingMode: .down,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        let divided = (value / unit) as NSDecimalNumber
        let flooredQuotient = divided.rounding(accordingToBehavior: handler)
        return (flooredQuotient as Decimal) * unit
    }
}
