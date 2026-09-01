import Foundation

/// 所得税の速算表の1区分。
public struct IncomeTaxBracket: Equatable, Sendable {
    /// この区分の課税所得の上限。`nil` は上限なし（最高税率区分）を表す。
    public let upperBound: Decimal?
    public let rate: Decimal
    /// 速算表の控除額（「課税所得 × 税率 − 控除額」で税額を求める）。
    public let baseDeduction: Decimal

    public init(upperBound: Decimal?, rate: Decimal, baseDeduction: Decimal) {
        self.upperBound = upperBound
        self.rate = rate
        self.baseDeduction = baseDeduction
    }
}
