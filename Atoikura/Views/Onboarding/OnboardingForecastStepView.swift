import SwiftUI

struct OnboardingForecastStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section {
                Text("今年の見込みを教えてください")
                    .font(.title2.bold())
                    .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section("年間売上見込み（任意）") {
                CurrencyTextField(value: $viewModel.annualRevenueForecast)
            }

            Section("年間経費見込み（任意）") {
                CurrencyTextField(value: $viewModel.annualExpenseForecast)
            }

            Section {
                CurrencyTextField(value: $viewModel.businessReserveAmount)
            } header: {
                Text("事業用に残しておきたい予備資金")
            } footer: {
                Text("急な出費や税金の支払いに備えて確保しておきたい金額の目安です。あとから変更できます。")
            }
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    OnboardingForecastStepView(viewModel: OnboardingViewModel())
}
