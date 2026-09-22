import SwiftUI
import UIKit

struct FumbleCheckView: View {
    @Environment(AppModel.self) private var model
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: HUTheme.space16) {
                Text("DON'T FUMBLE.")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(HUTheme.text)
                Text("Paste the message before it leaves. We check position, not grammar.")
                    .font(.subheadline)
                    .foregroundStyle(HUTheme.muted)

                TextEditor(text: $model.fumbleDraft)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(HUTheme.text)
                    .padding(HUTheme.space12)
                    .frame(minHeight: 140)
                    .background(HUTheme.surface)
                    .clipShape(.rect(cornerRadius: HUTheme.radiusM))
                    .accessibilityIdentifier(HUID.fumbleText)
                    .accessibilityLabel("Draft message")

                if let result = model.fumbleResult {
                    verdict(result)
                }
            }
            .padding(HUTheme.space24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            HUStickyBar {
                HUButton(title: "CHECK IT", kind: .primary, identifier: HUID.fumbleRun, isEnabled: model.canRunFumble) {
                    focused = false
                    Task { await model.runFumble() }
                }
            }
        }
        .background(HUTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: model.copiedFumble)
        .task(id: model.copiedFumble) {
            guard model.copiedFumble else { return }
            try? await Task.sleep(for: .seconds(2))
            model.copiedFumble = false
        }
        .onChange(of: model.fumbleDraft) { _, _ in
            model.copiedFumble = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
            }
        }
    }

    @ViewBuilder
    private func verdict(_ result: FumbleCheckResult) -> some View {
        let tone: HUBadge.Tone = {
            switch result.verdict {
            case .fumble: return .danger
            case .sendIt: return .go
            case .tighten: return .accent
            }
        }()
        let label: String = {
            switch result.verdict {
            case .fumble: return "FUMBLE"
            case .sendIt: return "SEND IT"
            case .tighten: return "TIGHTEN"
            }
        }()

        HUCard {
            VStack(alignment: .leading, spacing: HUTheme.space12) {
                HUBadge(text: label, tone: tone)
                    .accessibilityIdentifier(HUID.fumbleVerdict)
                Text(result.headline)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(HUTheme.text)
                Text(result.reason)
                    .font(.body)
                    .foregroundStyle(HUTheme.muted)
                if let improved = result.improvedMessage {
                    Text(improved)
                        .font(.body)
                        .foregroundStyle(HUTheme.text)
                        .padding(.top, 4)
                    Button("USE THIS") {
                        model.applyFumbleFix()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HUTheme.accent)
                    .frame(minHeight: 44, alignment: .leading)
                }
                if result.verdict == .sendIt {
                    Text("Copy your original. It's already the move.")
                        .font(.caption)
                        .foregroundStyle(HUTheme.muted)
                }
                if let text = model.fumbleCopyText {
                    HUButton(
                        title: model.copiedFumble ? "COPIED" : "COPY",
                        kind: .secondary,
                        identifier: HUID.fumbleCopy
                    ) {
                        UIPasteboard.general.string = text
                        model.copiedFumble = true
                    }
                }
            }
        }
    }
}
