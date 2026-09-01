import Foundation
import SwiftUI

/// 金額入力用のテキストフィールド。数字のみを受け付け、`Decimal?` にバインドする。
/// 入力中は生の数字を表示し、確定した値は下に「¥」区切り表示のプレビューを出す
/// （入力中にカンマを差し込むと編集中にカーソル位置がずれる問題を避けるための設計）。
struct CurrencyTextField: View {
    @Binding var value: Decimal?
    var placeholder: String = "0"

    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Text("¥")
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: text) { _, newValue in
                        applyChange(newValue)
                    }
            }
            if let value {
                Text(CurrencyFormatter.string(from: value))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: syncTextFromValue)
    }

    private func applyChange(_ newValue: String) {
        let digitsOnly = newValue.filter(\.isNumber)
        if digitsOnly != newValue {
            text = digitsOnly
            return
        }
        value = digitsOnly.isEmpty ? nil : Decimal(string: digitsOnly)
    }

    private func syncTextFromValue() {
        guard let value else {
            text = ""
            return
        }
        text = (value as NSDecimalNumber).stringValue
    }
}
