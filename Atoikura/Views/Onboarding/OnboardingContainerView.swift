import SwiftUI
import SwiftData

/// オンボーディング全体の進行を管理する。最大4ステップで、
/// どのステップからでも「あとで設定する」でホームへ進める。
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0
    @State private var saveErrorMessage: String?

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .padding(.horizontal)
                .padding(.top)
                .accessibilityLabel("オンボーディングの進行状況")

            TabView(selection: $currentStep) {
                OnboardingWelcomeStepView(viewModel: viewModel)
                    .tag(0)
                OnboardingFilingTypeStepView(viewModel: viewModel)
                    .tag(1)
                OnboardingForecastStepView(viewModel: viewModel)
                    .tag(2)
                OnboardingCompletionStepView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.default, value: currentStep)

            controls
        }
        .alert(
            "保存に失敗しました",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("OK") { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private var controls: some View {
        HStack {
            if currentStep > 0 {
                Button("戻る") {
                    currentStep -= 1
                }
            }

            Spacer()

            if currentStep < totalSteps - 1 {
                Button("あとで設定する") {
                    finishOnboarding()
                }
                .foregroundStyle(.secondary)

                Button("次へ") {
                    currentStep += 1
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("今年あと使えるお金を見てみましょう") {
                    finishOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private func finishOnboarding() {
        do {
            try viewModel.completeOnboarding(context: modelContext)
        } catch {
            saveErrorMessage = "しばらくしてからもう一度お試しください。"
        }
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [
            UserProfile.self,
            IncomeTransaction.self,
            ExpenseTransaction.self,
            TaxSettings.self,
            ReserveSettings.self,
            AppSettings.self
        ], inMemory: true)
}
