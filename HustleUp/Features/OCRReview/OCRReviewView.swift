import SwiftUI

struct OCRReviewView: View {
    @Environment(AppModel.self) private var model
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: HUTheme.space16) {
                Text("WE PULLED THIS")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(HUTheme.text)

                if let ocr = model.ocrResult {
                    HStack {
                        HUBadge(
                            text: ocr.isUncertain ? "UNCERTAIN" : "READABLE",
                            tone: ocr.isUncertain ? .accent : .go
                        )
                        if ocr.wasTruncated {
                            HUBadge(text: "TRIMMED", tone: .neutral)
                        }
                        Spacer()
                    }
                    Text(ocr.isEmpty
                         ? "No text turned up. Type what it said."
                         : "Edit anything that looks wrong, then analyze.")
                        .font(.subheadline)
                        .foregroundStyle(HUTheme.muted)
                }

                TextEditor(text: $model.composeText)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(HUTheme.text)
                    .padding(HUTheme.space12)
                    .frame(minHeight: 180)
                    .background(HUTheme.surface)
                    .clipShape(.rect(cornerRadius: HUTheme.radiusM))
                    .accessibilityIdentifier(HUID.ocrText)
                    .accessibilityLabel("Extracted screenshot text")
            }
            .padding(HUTheme.space24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            HUStickyBar {
                if model.canAnalyzeCurrentInput {
                    HUButton(title: "ANALYZE", kind: .primary, identifier: HUID.ocrAnalyze, isEnabled: true) {
                        focused = false
                        Task { await model.analyzeCurrentInput() }
                    }
                    HUButton(title: "TYPE IT INSTEAD", kind: .ghost, identifier: HUID.ocrTypeInstead) {
                        model.switchToTypedInput()
                    }
                } else {
                    HUButton(title: "TYPE IT INSTEAD", kind: .primary, identifier: HUID.ocrTypeInstead) {
                        model.switchToTypedInput()
                    }
                }
            }
        }
        .background(HUTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
            }
        }
    }
}
