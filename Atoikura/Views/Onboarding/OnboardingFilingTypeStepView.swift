import SwiftUI
import TaxEngine

struct OnboardingFilingTypeStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section {
                Text("申告方法")
                    .font(.title2.bold())
                    .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section {
                ForEach(FilingType.allCases, id: \.self) { type in
                    Button {
                        viewModel.filingType = type
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName)
                                    .font(.headline)
                                Text(description(for: type))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.filingType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            } footer: {
                Text("あとから設定画面で変更できます。わからない場合は「白色申告」のままで大丈夫です。")
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func description(for type: FilingType) -> String {
        switch type {
        case .blue: return "複式簿記などの要件を満たすと控除が受けられます"
        case .white: return "比較的シンプルな帳簿づけで申告できます"
        }
    }
}

#Preview {
    OnboardingFilingTypeStepView(viewModel: OnboardingViewModel())
}
