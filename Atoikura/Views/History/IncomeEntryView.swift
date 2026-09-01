import SwiftUI
import SwiftData

/// 売上の追加・編集画面。金額と日付を最優先で表示し、詳細項目は展開式にする。
struct IncomeEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: IncomeEntryViewModel
    @State private var showDetails: Bool
    @State private var errorMessage: String?

    init(transaction: IncomeTransaction? = nil) {
        let viewModel = IncomeEntryViewModel(transaction: transaction)
        _viewModel = State(initialValue: viewModel)
        _showDetails = State(initialValue: viewModel.hasDetailInput)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("金額") {
                    CurrencyTextField(value: $viewModel.amount)
                }

                Section("日付") {
                    DatePicker("日付", selection: $viewModel.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                if showDetails {
                    Section("詳細") {
                        TextField("取引先（任意）", text: $viewModel.clientName)
                        TextField("分類（任意）", text: $viewModel.category)
                        TextField("メモ（任意）", text: $viewModel.memo, axis: .vertical)
                        Toggle("入金済み", isOn: $viewModel.isPaid)
                    }
                } else {
                    Button {
                        withAnimation { showDetails = true }
                    } label: {
                        Label("詳細を追加", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "売上を編集" : "売上を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(viewModel.isSaveDisabled)
                }
            }
            .alert(
                "保存に失敗しました",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        do {
            try viewModel.save(context: modelContext)
            dismiss()
        } catch {
            errorMessage = "しばらくしてからもう一度お試しください。"
        }
    }
}

#Preview {
    IncomeEntryView()
        .modelContainer(for: [IncomeTransaction.self], inMemory: true)
}
