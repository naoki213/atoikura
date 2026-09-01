import SwiftUI

struct OnboardingCompletionStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            Text("準備ができました")
                .font(.title2.bold())
            Text("今年あと使えるお金を見てみましょう")
                .foregroundStyle(.secondary)

            DisclaimerText()
                .padding(.top, 12)

            Spacer()
        }
        .padding()
        .multilineTextAlignment(.center)
    }
}

#Preview {
    OnboardingCompletionStepView()
}
