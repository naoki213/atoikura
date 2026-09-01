import SwiftUI
import SwiftData

/// アプリで最も重要な画面。「今年あと使えるお金」を中心に据える。
struct HomeView: View {
    @Query(sort: \IncomeTransaction.date) private var incomeTransactions: [IncomeTransaction]
    @Query(sort: \ExpenseTransaction.date) private var expenseTransactions: [ExpenseTransaction]
    @Query private var userProfiles: [UserProfile]
    @Query private var taxSettingsList: [TaxSettings]
    @Query private var reserveSettingsList: [ReserveSettings]
    @Query private var appSettingsList: [AppSettings]

    @State private var isShowingBreakdown = true
    @State private var isPresentingIncomeEntry = false
    @State private var isPresentingExpenseEntry = false

    private var year: Int {
        appSettingsList.first?.selectedYear ?? Calendar.current.component(.year, from: .now)
    }

    private var viewModel: HomeViewModel {
        HomeViewModel.build(
            year: year,
            incomeTransactions: incomeTransactions,
            expenseTransactions: expenseTransactions,
            userProfile: userProfiles.first,
            taxSettings: taxSettingsList.first { $0.year == year },
            reserveSettings: reserveSettingsList.first
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    yearHeader

                    allowanceHero

                    if !viewModel.hasAnyTransaction {
                        Text("履歴タブ、またはこの画面右上の＋から売上・経費を登録すると、数字が更新されます。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    breakdownDisclosure
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.inline)
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
        }
    }

    private var yearHeader: some View {
        Text("\(String(year))年")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private var allowanceHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今年あと使えるお金")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.string(from: viewModel.breakdown.remainingAllowance))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.breakdown.remainingAllowance >= 0 ? Color.primary : Color.red)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityLabel(
                    "今年あと使えるお金 \(CurrencyFormatter.string(from: viewModel.breakdown.remainingAllowance))"
                )

            Text("現在の入力内容から算出した概算です")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var breakdownDisclosure: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { isShowingBreakdown.toggle() }
            } label: {
                HStack {
                    Text("内訳を見る")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: isShowingBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(16)

            if isShowingBreakdown {
                VStack(spacing: 14) {
                    breakdownRow(title: "今年の売上", amount: viewModel.breakdown.revenueForecast)
                    breakdownRow(title: "今年の経費", amount: viewModel.breakdown.expenseForecast)
                    Divider()
                    breakdownRow(title: "予想利益", amount: viewModel.breakdown.projectedProfit, emphasized: true)
                    breakdownRow(title: "税金・社会保険として確保", amount: viewModel.breakdown.taxAndSocialInsuranceReserve)
                    breakdownRow(
                        title: "事業用に残すお金",
                        amount: viewModel.breakdown.businessReserve + viewModel.breakdown.otherReserve
                    )

                    Text("税金・社会保険の金額は概算です。詳しくは設定画面をご確認ください。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func breakdownRow(title: String, amount: Decimal, emphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(emphasized ? .primary : .secondary)
            Spacer()
            Text(CurrencyFormatter.string(from: amount))
                .font(.body.monospacedDigit())
                .fontWeight(emphasized ? .semibold : .regular)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [
            UserProfile.self,
            IncomeTransaction.self,
            ExpenseTransaction.self,
            TaxSettings.self,
            ReserveSettings.self,
            AppSettings.self
        ], inMemory: true)
}
