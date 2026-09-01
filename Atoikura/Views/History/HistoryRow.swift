import SwiftUI

struct HistoryRow: View {
    let item: HistoryItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbolName)
                .foregroundStyle(item.tintColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                Text(item.date, format: .dateTime.month(.defaultDigits).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Text(signedAmountText)
                .font(.body.monospacedDigit())
                .foregroundStyle(item.signedAmount >= 0 ? Color.primary : Color.red)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var signedAmountText: String {
        let sign = item.signedAmount >= 0 ? "+" : "−"
        return sign + CurrencyFormatter.string(from: abs(item.signedAmount))
    }
}
