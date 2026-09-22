import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("HUSTLE UP")
                .font(.subheadline.weight(.bold))
                .tracking(3)
                .foregroundStyle(HUTheme.accent)
            Text("MAKE BETTER MOVES.")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(HUTheme.text)
                .padding(.top, HUTheme.space12)
            Text("SITUATION  →  EDGE  →  MOVE")
                .font(.caption.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(HUTheme.accent)
                .padding(.top, HUTheme.space16)
            Text("See what's on the table. Know your leverage. Pick one verb. Then execute.")
                .font(.body)
                .foregroundStyle(HUTheme.muted)
                .padding(.top, HUTheme.space12)
            Text("Three free moves. Analysis stays on this phone.")
                .font(.subheadline)
                .foregroundStyle(HUTheme.muted)
                .padding(.top, HUTheme.space8)
            Spacer()
            HUButton(title: "GET IN", kind: .primary, identifier: HUID.onboardingContinue) {
                model.completeOnboarding()
            }
        }
        .padding(HUTheme.space24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HUTheme.background.ignoresSafeArea())
    }
}
