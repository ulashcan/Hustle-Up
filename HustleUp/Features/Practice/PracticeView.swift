import SwiftUI

struct PracticeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !model.practiceDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: HUTheme.space8) {
                Text("LET'S RUN IT.")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(HUTheme.text)
                if let practice = model.practice {
                    Text("You're talking to \(practice.otherPartyRole).")
                        .font(.subheadline)
                        .foregroundStyle(HUTheme.muted)
                }
            }
            .padding(.horizontal, HUTheme.space24)
            .padding(.top, HUTheme.space16)
            .padding(.bottom, HUTheme.space12)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: HUTheme.space12) {
                        if let turns = model.practice?.turns, !turns.isEmpty {
                            ForEach(turns) { turn in
                                bubble(turn)
                                    .id(turn.id)
                            }
                        } else {
                            Text("Say the first line the way you would in the room.")
                                .font(.body)
                                .foregroundStyle(HUTheme.muted)
                        }
                    }
                    .padding(.horizontal, HUTheme.space24)
                    .padding(.bottom, HUTheme.space16)
                }
                .onChange(of: model.practice?.turns.count) { _, _ in
                    if let last = model.practice?.turns.last?.id {
                        if reduceMotion {
                            proxy.scrollTo(last, anchor: .bottom)
                        } else {
                            withAnimation {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: HUTheme.space12) {
                HStack(alignment: .bottom, spacing: HUTheme.space8) {
                    TextField("Your line", text: $model.practiceDraft, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(HUTheme.space12)
                        .background(HUTheme.surface)
                        .clipShape(.rect(cornerRadius: HUTheme.radiusM))
                        .focused($focused)
                        .accessibilityIdentifier(HUID.practiceInput)
                    Button("SEND") {
                        focused = false
                        Task { await model.sendPracticeTurn() }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 16)
                    .frame(minWidth: 52, minHeight: 44)
                    .background(canSend ? HUTheme.accent : HUTheme.muted)
                    .clipShape(.rect(cornerRadius: HUTheme.radiusM))
                    .disabled(!canSend)
                    .accessibilityIdentifier(HUID.practiceSend)
                    .accessibilityLabel("Send")
                }

                if (model.practice?.userTurnCount ?? 0) >= 1 {
                    HUButton(title: "THAT'S ENOUGH", kind: .secondary, identifier: HUID.practiceFinish) {
                        focused = false
                        Task { await model.finishPractice() }
                    }
                }
            }
            .padding(HUTheme.space16)
            .background(HUTheme.background)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(HUTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
            }
        }
        .onAppear { focused = true }
    }

    private func bubble(_ turn: PracticeTurn) -> some View {
        let isUser = turn.role == .user
        return Text(turn.text)
            .font(.body)
            .foregroundStyle(isUser ? Color.black : HUTheme.text)
            .padding(HUTheme.space12)
            .background(isUser ? HUTheme.accent : HUTheme.surface)
            .clipShape(.rect(cornerRadius: HUTheme.radiusM))
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .accessibilityLabel(isUser ? "You: \(turn.text)" : "Them: \(turn.text)")
    }
}
