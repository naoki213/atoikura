import SwiftUI
import SwiftData

/// 経費の追加・編集画面。金額・日付・カテゴリーを最優先で表示し、
/// メモと事業割合は詳細項目として展開式にする。
struct ExpenseEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ExpenseEntryViewModel
    @State private var showDetails: Bool
    @State private var errorMessage: String?

    init(transaction: ExpenseTransaction? = nil) {
        let viewModel = ExpenseEntryViewModel(transaction: transaction)
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

                Section("カテゴリー") {
                    Picker("カテゴリー", selection: $viewModel.category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.symbolName)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                if showDetails {
                    Section("詳細") {
                        TextField("メモ（任意）", text: $viewModel.memo, axis: .vertical)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("事業割合: \(viewModel.businessRatioPercent)%")
                            Stepper(
                                "事業割合",
                                value: $viewModel.businessRatioPercent,
                                in: 0...100,
                                step: 10
                            )
                            .labelsHidden()
                            Text("税計算には「金額 × 事業割合」を経費として使用します。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Button {
                        withAnimation { showDetails = true }
                    } label: {
                        Label("詳細を追加", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "経費を編集" : "経費を追加")
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
    ExpenseEntryView()
        .modelContainer(for: [ExpenseTransaction.self], inMemory: true)
}
