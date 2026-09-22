import SwiftUI
import UIKit

struct AnalysisView: View {
    @Environment(AppModel.self) private var model
    @State private var showRead = false
    @State private var copiedLine: String?

    var body: some View {
        Group {
            if let stored = model.analysis {
                content(stored)
            } else {
                HUEmptyState(
                    title: "NO MOVE YET",
                    detail: "Drop a screenshot or tell us what's happening."
                )
            }
        }
        .background(HUTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact(weight: .heavy), trigger: model.analysis?.id)
        .sensoryFeedback(.success, trigger: copiedLine)
        .task(id: copiedLine) {
            guard copiedLine != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            copiedLine = nil
        }
    }

    private func content(_ stored: StoredAnalysis) -> some View {
        let analysis = stored.analysis
        return ScrollView {
            VStack(alignment: .leading, spacing: HUTheme.space24) {
                if analysis.needsMoreContext {
                    needContext(analysis)
                } else {
                    MoveHero(analysis: analysis)
                    sayThis(analysis)
                    edgeMap(analysis)
                    if !analysis.suggestedActions.isEmpty {
                        section(title: "DO THIS", lines: analysis.suggestedActions)
                    }
                    otherMoves(analysis)
                    theRead(analysis)
                }
            }
            .padding(HUTheme.space24)
        }
        .safeAreaInset(edge: .bottom) {
            HUStickyBar {
                if analysis.needsMoreContext {
                    HUButton(title: "ADD DETAIL", kind: .primary, identifier: HUID.analysisAddDetail) {
                        model.addDetail()
                    }
                    HUButton(title: "DONE", kind: .ghost, identifier: HUID.analysisDone) {
                        model.goHome()
                    }
                } else {
                    nextActions
                }
            }
        }
    }

    private func needContext(_ analysis: SituationAnalysis) -> some View {
        VStack(alignment: .leading, spacing: HUTheme.space16) {
            HUSectionHeader(title: "HOLD UP")
            Text("NOT ENOUGH CONTEXT")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(HUTheme.accent)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier(HUID.analysisNeedContext)
                .accessibilityAddTraits(.isHeader)
            Text(analysis.situation)
                .font(.body)
                .foregroundStyle(HUTheme.text)
            HUBadge(text: EvidenceStrength.unknown.rawValue, tone: .neutral)
            if !analysis.missingContextQuestions.isEmpty {
                VStack(alignment: .leading, spacing: HUTheme.space8) {
                    HUSectionHeader(title: "TELL US")
                    ForEach(Array(analysis.missingContextQuestions.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.body)
                            .foregroundStyle(HUTheme.text)
                    }
                }
            }
        }
    }

    private func theRead(_ analysis: SituationAnalysis) -> some View {
        VStack(alignment: .leading, spacing: HUTheme.space16) {
            Button {
                showRead.toggle()
            } label: {
                HStack {
                    HUSectionHeader(title: "THE READ")
                    Spacer()
                    Text(showRead ? "HIDE" : "SHOW")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(HUTheme.accent)
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(HUID.analysisReadToggle)
            .accessibilityLabel(showRead ? "Hide the read" : "Show the read")

            if showRead {
                section(title: "SITUATION", lines: [analysis.situation])
                section(title: "YOUR EDGE", lines: analysis.userEdge)
                section(title: "THEIR EDGE", lines: analysis.otherSideEdge)
                if !analysis.sharedInterest.isEmpty {
                    section(title: "SHARED", lines: analysis.sharedInterest)
                }
                section(title: "RISK", lines: analysis.risks)
                if !analysis.knownFacts.isEmpty {
                    section(title: "KNOWN", lines: analysis.knownFacts)
                }
                if !analysis.assumptions.isEmpty {
                    section(title: "ASSUMPTIONS", lines: analysis.assumptions)
                }
                if !analysis.unknowns.isEmpty {
                    section(title: "UNKNOWN", lines: analysis.unknowns)
                }
            }
        }
    }

    private func sayThis(_ analysis: SituationAnalysis) -> some View {
        Group {
            if let line = SuggestedCopy.primarySendable(analysis.suggestedResponses) {
                lineCard(title: "SAY THIS", line: line, allowCopy: true)
                    .accessibilityIdentifier(HUID.analysisSayThis)
            } else if let hold = SuggestedCopy.holdLine(analysis.suggestedResponses) {
                lineCard(title: "HOLD THIS", line: hold, allowCopy: false)
                    .accessibilityIdentifier(HUID.analysisHold)
            }
        }
    }

    private func lineCard(title: String, line: String, allowCopy: Bool) -> some View {
        VStack(alignment: .leading, spacing: HUTheme.space8) {
            HUSectionHeader(title: title)
            HUCard {
                VStack(alignment: .leading, spacing: HUTheme.space8) {
                    Text(line)
                        .font(.body)
                        .foregroundStyle(HUTheme.text)
                    if SuggestedCopy.hasPlaceholder(line) {
                        Text("Swap the brackets before you send.")
                            .font(.caption)
                            .foregroundStyle(HUTheme.muted)
                    }
                    if allowCopy {
                        Button(copiedLine == line ? "COPIED" : "COPY") {
                            UIPasteboard.general.string = line
                            copiedLine = line
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HUTheme.accent)
                        .frame(minHeight: 44, alignment: .leading)
                        .accessibilityIdentifier(HUID.analysisCopy)
                    }
                }
            }
        }
    }

    private func edgeMap(_ analysis: SituationAnalysis) -> some View {
        VStack(alignment: .leading, spacing: HUTheme.space12) {
            if let yours = analysis.userEdge.first {
                compactRow(title: "YOUR EDGE", line: yours)
            }
            if let theirs = analysis.otherSideEdge.first {
                compactRow(title: "THEIR EDGE", line: theirs)
            }
            if let shared = analysis.sharedInterest.first {
                compactRow(title: "SHARED", line: shared)
            }
            if let risk = analysis.risks.first {
                compactRow(title: "RISK", line: risk)
            }
        }
        .accessibilityIdentifier(HUID.analysisEdgeMap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Edge map")
    }

    private func otherMoves(_ analysis: SituationAnalysis) -> some View {
        let alts = analysis.alternativeMoves
        return Group {
            if !alts.isEmpty {
                VStack(alignment: .leading, spacing: HUTheme.space8) {
                    HUSectionHeader(title: "IF NOT THIS")
                    ForEach(alts) { option in
                        HUCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.move.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(HUTheme.accent)
                                Text(option.purpose)
                                    .font(.subheadline)
                                    .foregroundStyle(HUTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .accessibilityIdentifier(HUID.analysisOtherMoves)
            }
        }
    }

    private func compactRow(title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HUSectionHeader(title: title)
            Text(line)
                .font(.body)
                .foregroundStyle(HUTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var nextActions: some View {
        VStack(spacing: HUTheme.space12) {
            HUButton(title: "FUMBLE CHECK", kind: .primary, identifier: HUID.analysisFumble) {
                model.openFumble()
            }
            HUButton(title: "PRACTICE", kind: .secondary, identifier: HUID.analysisPractice) {
                model.openPractice()
            }
            HUButton(title: "DONE", kind: .ghost, identifier: HUID.analysisDone) {
                model.goHome()
            }
        }
    }

    private func section(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: HUTheme.space8) {
            HUSectionHeader(title: title)
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.body)
                    .foregroundStyle(HUTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct HUEmptyState: View {
    var title: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: HUTheme.space12) {
            Text(title)
                .font(.title2.weight(.heavy))
                .foregroundStyle(HUTheme.text)
            Text(detail)
                .font(.body)
                .foregroundStyle(HUTheme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(HUTheme.space24)
    }
}

struct MoveHero: View {
    var analysis: SituationAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: HUTheme.space8) {
            HUSectionHeader(title: "YOUR MOVE")
            Text(analysis.move.displayName)
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(HUTheme.accent)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .accessibilityIdentifier(HUID.analysisMove)
                .accessibilityLabel("Your move: \(analysis.move.rawValue). \(analysis.moveReason)")
                .accessibilityAddTraits(.isHeader)
            Text(analysis.moveReason)
                .font(.body)
                .foregroundStyle(HUTheme.text)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                HUBadge(text: analysis.evidenceStrength.rawValue, tone: .accent)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Evidence \(analysis.evidenceStrength.rawValue)")
        }
    }
}
