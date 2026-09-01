import SwiftUI
import SwiftData

/// 売上・経費の履歴一覧。すべて/売上/経費で切り替え、月別にグループ表示する。
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IncomeTransaction.date, order: .reverse) private var incomeTransactions: [IncomeTransaction]
    @Query(sort: \ExpenseTransaction.date, order: .reverse) private var expenseTransactions: [ExpenseTransaction]

    @State private var segment: HistorySegment = .all
    @State private var isPresentingIncomeEntry = false
    @State private var isPresentingExpenseEntry = false
    @State private var editingIncome: IncomeTransaction?
    @State private var editingExpense: ExpenseTransaction?
    @State private var pendingDeleteItem: HistoryItem?

    var body: some View {
        NavigationStack {
            Group {
                if sections.isEmpty {
                    ContentUnavailableView(
                        "記録がありません",
                        systemImage: "tray",
                        description: Text("右上の＋から売上・経費を追加できます")
                    )
                } else {
                    List {
                        ForEach(sections) { section in
                            Section(section.title) {
                                ForEach(section.items) { item in
                                    HistoryRow(item: item)
                                        .contentShape(Rectangle())
                                        .onTapGesture { handleTap(item) }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                pendingDeleteItem = item
                                            } label: {
                                                Label("削除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                Picker("表示", selection: $segment) {
                    ForEach(HistorySegment.allCases) { seg in
                        Text(seg.title).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .navigationTitle("履歴")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            isPresentingIncomeEntry = true
                        } label: {
                            Label("売上を追加", systemImage: "arrow.down.circle")
                        }
                        Button {
                            isPresentingExpenseEntry = true
                        } label: {
                            Label("経費を追加", systemImage: "arrow.up.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("売上・経費を追加")
                }
            }
            .sheet(isPresented: $isPresentingIncomeEntry) {
                IncomeEntryView()
            }
            .sheet(isPresented: $isPresentingExpenseEntry) {
                ExpenseEntryView()
            }
            .sheet(item: $editingIncome) { transaction in
                IncomeEntryView(transaction: transaction)
            }
            .sheet(item: $editingExpense) { transaction in
                ExpenseEntryView(transaction: transaction)
            }
            .confirmationDialog(
                "この記録を削除しますか？",
                isPresented: Binding(
                    get: { pendingDeleteItem != nil },
                    set: { if !$0 { pendingDeleteItem = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive, action: performDelete)
                Button("キャンセル", role: .cancel) { pendingDeleteItem = nil }
            }
        }
    }

    private var filteredItems: [HistoryItem] {
        var items: [HistoryItem] = []
        if segment != .expense {
            items.append(contentsOf: incomeTransactions.map(HistoryItem.income))
        }
        if segment != .income {
            items.append(contentsOf: expenseTransactions.map(HistoryItem.expense))
        }
        return items
    }

    private var sections: [HistorySection] {
        HistoryGrouping.monthlySections(items: filteredItems)
    }

    private func handleTap(_ item: HistoryItem) {
        switch item {
        case .income(let transaction): editingIncome = transaction
        case .expense(let transaction): editingExpense = transaction
        }
    }

    private func performDelete() {
        guard let pendingDeleteItem else { return }
        switch pendingDeleteItem {
        case .income(let transaction): modelContext.delete(transaction)
        case .expense(let transaction): modelContext.delete(transaction)
        }
        try? modelContext.save()
        self.pendingDeleteItem = nil
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [IncomeTransaction.self, ExpenseTransaction.self], inMemory: true)
}
