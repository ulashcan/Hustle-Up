import SwiftUI

struct ComposeView: View {
    @Environment(AppModel.self) private var model
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: HUTheme.space16) {
                Text("TELL US WHAT'S HAPPENING")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(HUTheme.text)
                Text("People, power, what was said. The messy version is fine.")
                    .font(.subheadline)
                    .foregroundStyle(HUTheme.muted)

                TextEditor(text: $model.composeText)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(HUTheme.text)
                    .padding(HUTheme.space12)
                    .frame(minHeight: 180)
                    .background(HUTheme.surface)
                    .clipShape(.rect(cornerRadius: HUTheme.radiusM))
                    .accessibilityIdentifier(HUID.composeText)
                    .accessibilityLabel("Situation text")

                Text("\(model.composeText.count) / \(TextCleaner.maxCharacters)")
                    .font(.caption)
                    .foregroundStyle(model.composeText.count > TextCleaner.maxCharacters - 400 ? HUTheme.accent : HUTheme.muted)
                if model.composeText.count > TextCleaner.maxCharacters {
                    Text("We'll trim this to \(TextCleaner.maxCharacters) characters on analyze.")
                        .font(.caption)
                        .foregroundStyle(HUTheme.accent)
                }
            }
            .padding(HUTheme.space24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            HUStickyBar {
                HUButton(title: "ANALYZE", kind: .primary, identifier: HUID.composeAnalyze, isEnabled: model.canAnalyzeCurrentInput) {
                    focused = false
                    Task { await model.analyzeCurrentInput() }
                }
            }
        }
        .background(HUTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
            }
        }
        .onAppear { focused = true }
    }
}
