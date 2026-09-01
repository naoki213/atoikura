import Foundation

public struct NationalHealthInsuranceResult: Equatable, Sendable {
    public let annualAmount: Decimal

    /// ユーザーが金額を入力済みかどうか。falseの場合、`annualAmount` は0（未算入）として扱われている。
    public let isUserProvided: Bool
}

/// 国民健康保険料の計算。
///
/// 国民健康保険料は自治体ごとに料率・均等割・上限額が大きく異なり、所得だけから
/// 一意に算出することはできないため、自動計算は行わず、ユーザーが入力した年額を
/// そのまま結果として返す（DEVELOPMENT.md「国民健康保険はユーザー手入力方式にした理由」参照）。
public struct NationalHealthInsuranceCalculator {
    public init() {}

    public func calculate(profile: TaxProfile) -> NationalHealthInsuranceResult {
        NationalHealthInsuranceResult(
            annualAmount: profile.hasSetNationalHealthInsuranceAmount ? profile.nationalHealthInsuranceAnnualAmount : 0,
            isUserProvided: profile.hasSetNationalHealthInsuranceAmount
        )
    }
}
