import SwiftUI

struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: HUTheme.space16) {
            Text("PRO")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(HUTheme.accent)
            Text("UNLIMITED MOVES.")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(HUTheme.text)
            Text(copy)
                .font(.body)
                .foregroundStyle(HUTheme.muted)

            VStack(alignment: .leading, spacing: HUTheme.space8) {
                bullet("Unlimited analyses")
                bullet("Fumble Check before you send")
                bullet("Practice the room")
                bullet("History on this device")
                bullet("See which moves actually landed")
            }
            .padding(.vertical, HUTheme.space8)

            Spacer()

            #if DEBUG
            HUButton(title: "PREVIEW PRO", kind: .primary, identifier: HUID.paywallPreview) {
                model.enableProPreview()
                dismiss()
            }
            #endif

            Button("Not now") {
                dismiss()
            }
            .font(.body)
            .foregroundStyle(HUTheme.muted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)

            #if DEBUG
            Text("StoreKit billing isn’t wired yet. Preview unlocks Pro on this device so you can test the product.")
                .font(.caption)
                .foregroundStyle(HUTheme.muted)
            #else
            Text("StoreKit billing isn’t wired yet. Free covers three analyses on this device.")
                .font(.caption)
                .foregroundStyle(HUTheme.muted)
            #endif
        }
        .padding(HUTheme.space24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(HUTheme.background.ignoresSafeArea())
        .accessibilityIdentifier(HUID.paywall)
    }

    private var copy: String {
        switch model.paywallFeature {
        case .fumbleCheck:
            return "Fumble Check is Pro. Don’t send the paragraph that gives the game away."
        case .practice:
            return "Practice is Pro. Run the conversation before you do it live."
        case .history:
            return "History and your hustle profile are Pro. Counts from moves you marked — not a personality test."
        default:
            return "Free covers three analyses. After that, Pro keeps you in the loop."
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: HUTheme.space8) {
            Text("→")
                .foregroundStyle(HUTheme.accent)
            Text(text)
                .foregroundStyle(HUTheme.text)
        }
        .font(.body)
    }
}
