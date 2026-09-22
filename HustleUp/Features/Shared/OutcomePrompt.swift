import SwiftUI

struct OutcomePrompt: View {
    var item: StoredAnalysis
    var identifier: String
    var onSelect: (MoveOutcome) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HUTheme.space12) {
            HUSectionHeader(title: "DID IT WORK?")
            if item.outcome == nil {
                Text("After you used the move.")
                    .font(.caption)
                    .foregroundStyle(HUTheme.muted)
            }
            if let outcome = item.outcome {
                HUBadge(text: outcome.result.displayName, tone: badgeTone(outcome.result))
                Text(outcome.lesson)
                    .font(.body)
                    .foregroundStyle(HUTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HUTheme.space8) {
                    ForEach(MoveOutcome.allCases) { option in
                        Button(option.displayName) {
                            onSelect(option)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HUTheme.text)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(HUTheme.surfaceRaised)
                        .clipShape(.rect(cornerRadius: HUTheme.radiusS))
                        .buttonStyle(HUPressStyle())
                        .accessibilityIdentifier(outcomeIdentifier(for: option))
                    }
                }
            }
        }
        .accessibilityIdentifier(identifier)
        .accessibilityElement(children: .contain)
    }

    private func outcomeIdentifier(for option: MoveOutcome) -> String {
        switch option {
        case .yes: HUID.outcomeYes
        case .no: HUID.outcomeNo
        case .partly: HUID.outcomePartly
        case .notSure: HUID.outcomeNotSure
        }
    }

    private func badgeTone(_ result: MoveOutcome) -> HUBadge.Tone {
        switch result {
        case .yes: .go
        case .no: .danger
        case .partly, .notSure: .accent
        }
    }
}
