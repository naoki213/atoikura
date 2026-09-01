import SwiftUI
import SwiftData

/// 年間の売上・経費予測。自動予測（実績ベースの単純年間換算）と手動設定を切り替えられる。
struct ForecastView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IncomeTransaction.date) private var incomeTransactions: [IncomeTransaction]
    @Query(sort: \ExpenseTransaction.date) private var expenseTransactions: [ExpenseTransaction]
    @Query private var taxSettingsList: [TaxSettings]
    @Query private var appSettingsList: [AppSettings]

    @State private var isRevenueManual = false
    @State private var manualRevenueAmount: Decimal?
    @State private var isExpenseManual = false
    @State private var manualExpenseAmount: Decimal?
    /// 直近に読み込んだ年度。`year`（対象年度）と食い違ったら、その年度のTaxSettings内容へ
    /// 読み込み直す（設定タブで対象年度を変更してこの画面に戻ってきた場合に対応するため）。
    @State private var loadedYear: Int?
    @State private var errorMessage: String?

    private var year: Int {
        appSettingsList.first?.selectedYear ?? Calendar.current.component(.year, from: .now)
    }

    private var currentTaxSettings: TaxSettings? {
        taxSettingsList.first { $0.year == year }
    }

    private var actuals: AnnualActuals {
        AnnualSummaryService.actuals(
            year: year,
            incomeTransactions: incomeTransactions,
            expenseTransactions: expenseTransactions
        )
    }

    private var autoForecast: AnnualForecast {
        AnnualForecastService.forecast(actuals: actuals, manualRevenueForecast: nil, manualExpenseForecast: nil)
    }

    private var revenueForecast: Decimal {
        isRevenueManual ? (manualRevenueAmount ?? 0) : autoForecast.revenueForecast
    }

    private var expenseForecast: Decimal {
        isExpenseManual ? (manualExpenseAmount ?? 0) : autoForecast.expenseForecast
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("実績をもとに、今年1年分の見込みを自動計算しています。必要に応じて金額を直接指定できます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)

                Section("今年の売上予測") {
                    Toggle("手動で設定する", isOn: $isRevenueManual)
                    if isRevenueManual {
                        CurrencyTextField(value: $manualRevenueAmount)
                    } else {
                        autoForecastRow(amount: autoForecast.revenueForecast)
                    }
                }

                Section("今年の経費予測") {
                    Toggle("手動で設定する", isOn: $isExpenseManual)
                    if isExpenseManual {
                        CurrencyTextField(value: $manualExpenseAmount)
                    } else {
                        autoForecastRow(amount: autoForecast.expenseForecast)
                    }
                }

                Section("予想利益") {
                    HStack {
                        Text("売上予測 − 経費予測")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.string(from: revenueForecast - expenseForecast))
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                }
            }
            .navigationTitle("予測")
            .onAppear(perform: loadValuesIfYearChanged)
            .onChange(of: year) { _, _ in loadValuesIfYearChanged() }
            .onChange(of: isRevenueManual) { _, _ in save() }
            .onChange(of: manualRevenueAmount) { _, _ in save() }
            .onChange(of: isExpenseManual) { _, _ in save() }
            .onChange(of: manualExpenseAmount) { _, _ in save() }
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

    private func autoForecastRow(amount: Decimal) -> some View {
        HStack {
            Text("自動予測")
                .foregroundStyle(.secondary)
            Spacer()
            Text(CurrencyFormatter.string(from: amount))
                .font(.body.monospacedDigit())
        }
    }

    private func loadValuesIfYearChanged() {
        guard loadedYear != year else { return }
        manualRevenueAmount = currentTaxSettings?.manualRevenueForecast
        manualExpenseAmount = currentTaxSettings?.manualExpenseForecast
        isRevenueManual = manualRevenueAmount != nil
        isExpenseManual = manualExpenseAmount != nil
        loadedYear = year
    }

    private func save() {
        guard loadedYear == year else { return }
        let targetYear = year
        do {
            let existing = try modelContext.fetch(
                FetchDescriptor<TaxSettings>(predicate: #Predicate<TaxSettings> { $0.year == targetYear })
            ).first
            let settings: TaxSettings
            if let existing {
                settings = existing
            } else {
                settings = TaxSettings(year: targetYear)
                modelContext.insert(settings)
            }
            settings.manualRevenueForecast = isRevenueManual ? manualRevenueAmount : nil
            settings.manualExpenseForecast = isExpenseManual ? manualExpenseAmount : nil
            try modelContext.save()
        } catch {
            errorMessage = "しばらくしてからもう一度お試しください。"
        }
    }
}

#Preview {
    ForecastView()
        .modelContainer(for: [
            IncomeTransaction.self,
            ExpenseTransaction.self,
            TaxSettings.self,
            AppSettings.self
        ], inMemory: true)
}
