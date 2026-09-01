import SwiftUI

struct OnboardingWelcomeStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("あといくらへようこそ")
                        .font(.title2.bold())
                    Text("売上・経費・税金をもとに、今年あと使えるお金を把握できるようにします。")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section("表示名（任意）") {
                TextField("屋号やお名前", text: $viewModel.displayName)
            }

            Section("事業開始年") {
                Picker("事業開始年", selection: $viewModel.businessStartYear) {
                    ForEach(viewModel.businessStartYearRange.reversed(), id: \.self) { year in
                        Text("\(String(year))年").tag(year)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    OnboardingWelcomeStepView(viewModel: OnboardingViewModel())
}
