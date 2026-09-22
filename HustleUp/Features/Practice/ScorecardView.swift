import SwiftUI

struct ScorecardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HUTheme.space24) {
                Text("HOW YOU DID")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(HUTheme.text)
                    .accessibilityIdentifier(HUID.scorecard)

                if let card = model.scorecard {
                    score("CONFIDENCE", card.confidence)
                    score("CLARITY", card.clarity)
                    score("POSITIONING", card.strategicPositioning)
                    score("LEVERAGE", card.leveragePreservation)
                    score("TIMING", card.timing)
                    score("RISK", card.riskManagement)

                    narrative(title: "WHAT YOU DID", body: card.whatYouDid)
                    narrative(title: "WHAT WORKED", body: card.whatWorked)
                    narrative(title: "WHAT HURT YOU", body: card.whatHurt)
                    narrative(title: "NEXT MOVE", body: card.nextMove)
                }
            }
            .padding(HUTheme.space24)
        }
        .safeAreaInset(edge: .bottom) {
            HUStickyBar {
                HUButton(title: "TRY AGAIN", kind: .primary) {
                    model.tryPracticeAgain()
                }
                HUButton(title: "DONE", kind: .ghost) {
                    model.goHome()
                }
            }
        }
        .background(HUTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact(weight: .medium), trigger: model.scorecard?.confidence)
    }

    private func narrative(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: HUTheme.space8) {
            HUSectionHeader(title: title)
            Text(body)
                .font(.body)
                .foregroundStyle(HUTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(body)")
    }

    private func score(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HUSectionHeader(title: title)
                Spacer()
                Text("\(value)/10")
                    .font(.headline)
                    .foregroundStyle(HUTheme.accent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(HUTheme.surfaceRaised)
                    Rectangle()
                        .fill(HUTheme.accent)
                        .frame(width: geo.size.width * CGFloat(value) / 10)
                }
            }
            .frame(height: 6)
            .clipShape(.rect(cornerRadius: 3))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value) out of 10")
    }
}
