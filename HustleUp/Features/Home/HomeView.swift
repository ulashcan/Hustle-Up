import PhotosUI
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HUTheme.space24) {
                HStack {
                    Text("HUSTLE UP")
                        .font(.caption.weight(.bold))
                        .tracking(2.4)
                        .foregroundStyle(HUTheme.muted)
                    Spacer()
                    Button("Settings", systemImage: "gearshape") {
                        model.path.append(.settings)
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(HUTheme.text)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier(HUID.homeSettings)
                }

                Text("WHAT'S THE MOVE?")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(HUTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(HUID.homeHeadline)
                    .accessibilityAddTraits(.isHeader)

                if !model.isPro {
                    let n = model.remainingFreeAnalyses
                    Text(model.remainingMovesHeadline)
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(n == 0 ? HUTheme.accent : HUTheme.muted)
                        .accessibilityIdentifier(HUID.homeRemaining)
                }

                VStack(spacing: HUTheme.space12) {
                    HUButton(title: "DROP A SCREENSHOT", kind: .primary, systemImage: "photo", identifier: HUID.homeScreenshot) {
                        showPicker = true
                    }

                    HUButton(title: "TELL US WHAT'S HAPPENING", kind: .secondary, identifier: HUID.homeType) {
                        model.openCompose()
                    }

                    if !model.isPro, model.remainingFreeAnalyses == 0 {
                        HUButton(title: "UNLOCK PRO", kind: .ghost, identifier: HUID.homeUnlock) {
                            model.present(.paywallRequired(.analysis))
                        }
                    }
                }

                if let last = model.lastMove {
                    VStack(alignment: .leading, spacing: HUTheme.space12) {
                        Button {
                            model.openLastMove()
                        } label: {
                            HUCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    HUSectionHeader(title: "LAST MOVE")
                                    Text(last.analysis.move.displayName)
                                        .font(.title3.weight(.heavy))
                                        .foregroundStyle(HUTheme.accent)
                                    Text(last.analysis.moveReason)
                                        .font(.subheadline)
                                        .foregroundStyle(HUTheme.muted)
                                        .lineLimit(2)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier(HUID.homeLastMove)
                        .accessibilityLabel("Last move: \(last.analysis.move.rawValue). \(last.analysis.moveReason)")
                        .accessibilityHint("Opens the last analysis from this session")

                        OutcomePrompt(item: last, identifier: HUID.homeOutcome) { result in
                            model.recordOutcome(result, for: last.id)
                        }
                    }
                }

                if model.isPro {
                    Button {
                        model.openProfile()
                    } label: {
                        HUCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HUSectionHeader(title: "HUSTLE PROFILE")
                                Text(model.profileObservations.isEmpty ? "No pattern yet." : model.profileObservations[0].title)
                                    .font(.headline)
                                    .foregroundStyle(HUTheme.text)
                                Text("Counts from moves you marked. Not a diagnosis.")
                                    .font(.caption)
                                    .foregroundStyle(HUTheme.muted)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier(HUID.homeProfile)
                    .accessibilityLabel("Hustle profile")
                }

                VStack(alignment: .leading, spacing: HUTheme.space8) {
                    HUSectionHeader(title: "OR START HERE")
                    ForEach(ExamplePrompt.allCases) { example in
                        Button {
                            model.openCompose(example: example)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: HUTheme.space12) {
                                Text(example.label)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(HUTheme.text)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: HUTheme.space8)
                                Text("→")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(HUTheme.accent)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier("home.example.\(example.id)")
                    }
                }
                .padding(.top, HUTheme.space8)

                if model.isPro, !model.history.isEmpty {
                    VStack(alignment: .leading, spacing: HUTheme.space8) {
                        HUSectionHeader(title: "RECENT")
                        ForEach(model.history.filter { !$0.analysis.needsMoreContext && $0.id != model.lastMove?.id }.prefix(5)) { item in
                            Button {
                                model.openStored(item)
                            } label: {
                                HUCard {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(item.analysis.move.displayName)
                                                .font(.headline)
                                                .foregroundStyle(HUTheme.accent)
                                            Spacer(minLength: HUTheme.space8)
                                            if let outcome = item.outcome {
                                                HUBadge(text: outcome.result.displayName, tone: .neutral)
                                            }
                                        }
                                        Text(item.analysis.situation)
                                            .font(.caption)
                                            .foregroundStyle(HUTheme.muted)
                                            .lineLimit(2)
                                        Text(item.analysis.moveReason)
                                            .font(.caption)
                                            .foregroundStyle(HUTheme.muted)
                                            .lineLimit(1)
                                        if let lesson = item.outcome?.lesson {
                                            Text(lesson)
                                                .font(.subheadline)
                                                .foregroundStyle(HUTheme.text)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(historyLabel(item))
                        }
                    }
                }
            }
            .padding(HUTheme.space24)
        }
        .background(HUTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                await loadPickerItem(newValue)
                pickerItem = nil
            }
        }
    }

    private func historyLabel(_ item: StoredAnalysis) -> String {
        let outcome = item.outcome.map { "Outcome \($0.result.displayName). \($0.lesson)" } ?? "No outcome yet"
        return "\(item.analysis.move.rawValue). \(item.analysis.moveReason). \(outcome)"
    }

    private func loadPickerItem(_ item: PhotosPickerItem) async {
        do {
            guard let imported = try await item.loadTransferable(type: ImportedImageData.self) else {
                model.present(.imageUnsupported)
                return
            }
            await model.importImageData(imported.data)
        } catch {
            model.present(.cancelled)
        }
    }
}
