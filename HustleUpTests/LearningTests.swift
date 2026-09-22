import Foundation
import Testing
@testable import HustleUp

struct OutcomeLessonTests {
    @Test func waitYesDoesNotInventAPersonality() {
        let lesson = OutcomeLesson.copy(move: .wait, outcome: .yes, category: .reply)
        #expect(!lesson.lowercased().contains("anxious"))
        #expect(!lesson.lowercased().contains("you always"))
        #expect(lesson.lowercased().contains("wait"))
    }

    @Test func notSureRefusesToRewriteTheMove() {
        let lesson = OutcomeLesson.copy(move: .counter, outcome: .notSure, category: .negotiation)
        #expect(lesson.lowercased().contains("too early") || lesson.lowercased().contains("maybe"))
    }
}

struct HustleProfileBuilderTests {
    @Test func emptyUntilTwoMatchingOutcomes() throws {
        let one = try stored(move: .counter, outcome: .no)
        #expect(HustleProfileBuilder.observations(from: [one]).isEmpty)

        let two = try stored(move: .counter, outcome: .no)
        let notes = HustleProfileBuilder.observations(from: [one, two])
        #expect(notes.count == 1)
        #expect(notes[0].count == 2)
        #expect(notes[0].title.lowercased().contains("counter"))
        #expect(notes[0].detail.lowercased().contains("2"))
        #expect(notes[0].detail.lowercased().contains("not a personality") || notes[0].detail.lowercased().contains("not a diagnosis"))
        let blob = notes.map { $0.title + $0.detail + $0.samples.joined() }.joined().lowercased()
        #expect(!blob.contains("secret conversation"))
        #expect(!blob.contains("80k"))
        #expect(!blob.contains("over-explain"))
    }

    @Test func mixedResultsDoNotBecomeAlways() throws {
        let a = try stored(move: .ask, outcome: .yes)
        let b = try stored(move: .ask, outcome: .no)
        #expect(HustleProfileBuilder.observations(from: [a, b]).isEmpty)
    }

    @Test func ignoresItemsWithoutOutcomesAndIgnoresInsufficient() throws {
        let pending = try stored(move: .send, outcome: nil)
        let thin = try stored(move: .ask, outcome: .yes, needsContext: true)
        let real = try stored(move: .send, outcome: .yes)
        let real2 = try stored(move: .send, outcome: .yes)
        let notes = HustleProfileBuilder.observations(from: [pending, thin, real, real2])
        #expect(notes.contains { $0.samples.contains("SEND → YES") })
        #expect(!notes.contains { $0.samples.contains("ASK → YES") })
    }

    @Test func practiceTurnsAreNotEvidence() {
        _ = PracticeSession(id: UUID(), scenario: "raise", otherPartyRole: "BOSS", turns: [], isComplete: true)
        #expect(HustleProfileBuilder.observations(from: []).isEmpty)
    }
}

@MainActor
struct OutcomeStoreTests {
    @Test func recordsOutcomeWithoutImageBytes() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("learn-\(UUID().uuidString).json")
        let store = FileAnalysisStore(fileURL: url, cap: 5)
        var item = try stored(move: .counter, outcome: nil)
        store.append(item)
        item.outcome = MoveOutcomeRecord(
            result: .yes,
            recordedAt: Date(),
            lesson: OutcomeLesson.copy(move: .counter, outcome: .yes, category: .negotiation)
        )
        store.update(item)
        let data = try Data(contentsOf: url)
        let raw = String(decoding: data, as: UTF8.self)
        #expect(raw.contains("\"yes\""))
        #expect(!raw.contains("pngData"))
        let reloaded = FileAnalysisStore(fileURL: url, cap: 5)
        #expect(reloaded.items.first?.outcome?.result == .yes)
        #expect(reloaded.items.first?.outcome?.lesson.isEmpty == false)
    }

    @Test func legacyJSONWithoutOutcomeStillLoads() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-\(UUID().uuidString).json")
        let item = try stored(move: .wait, outcome: nil)
        let data = try JSONEncoder().encode([item])
        try data.write(to: url)
        let store = FileAnalysisStore(fileURL: url, cap: 5)
        #expect(store.items.count == 1)
        #expect(store.items.first?.outcome == nil)
    }
}

@MainActor
struct AppModelLearningTests {
    @Test func recordingOutcomePersistsOnLastMove() async {
        let (model, analytics) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        let id = model.lastMove?.id
        #expect(id != nil)
        model.goHome()
        model.recordOutcome(.partly)
        #expect(model.lastMove?.id == id)
        #expect(model.lastMove?.outcome?.result == .partly)
        #expect(model.history.first?.outcome?.result == .partly)
        #expect(analytics.records.contains { $0.event == .outcomeRecorded && $0.parameters.outcome == "partly" })
        let dump = String(describing: analytics.records)
        #expect(!dump.contains("discount on the remaining"))
    }

    @Test func profileIsEmptyForFreeUsersEvenWithRepeats() async {
        let (model, _) = TestAppFactory.model(pro: false)
        model.composeText = "They offered 90k for the role. Should I take it or counter?"
        await model.analyzeCurrentInput()
        model.recordOutcome(.no)
        model.path = []
        model.composeText = "The client sent a lowball offer at half my rate and wants an answer today."
        await model.analyzeCurrentInput()
        model.recordOutcome(.no)
        #expect(model.profileObservations.isEmpty)
    }

    @Test func proProfileUsesCountsNotDiagnoses() async {
        let (model, _) = TestAppFactory.model(pro: true)
        model.composeText = "They offered 90k for the role. Should I take it or counter?"
        await model.analyzeCurrentInput()
        model.recordOutcome(.no)
        model.path = []
        model.composeText = "The client sent a lowball offer at half my rate and wants an answer today."
        await model.analyzeCurrentInput()
        model.recordOutcome(.no)
        let notes = model.profileObservations
        #expect(!notes.isEmpty)
        let blob = notes.map(\.detail).joined().lowercased()
        #expect(!blob.contains("you are the kind of person"))
        #expect(blob.contains("not a diagnosis") || blob.contains("a count"))
    }

    @Test func openProfileIsGated() {
        let (model, analytics) = TestAppFactory.model(pro: false)
        model.openProfile()
        #expect(model.showPaywall)
        #expect(model.paywallFeature == .history)
        #expect(analytics.records.contains { $0.event == .paywallViewed })
        #expect(!model.path.contains(.profile))
    }

    @Test func deleteAllClearsOutcomes() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        model.recordOutcome(.yes)
        model.deleteAllData()
        #expect(model.lastMove == nil)
        #expect(model.profileObservations.isEmpty)
    }
}

private func stored(
    move: MoveVerb,
    outcome: MoveOutcome?,
    needsContext: Bool = false
) throws -> StoredAnalysis {
    let analysis = try SituationAnalysis(
        situation: "Offer on the table.",
        userEdge: ["Walk"],
        otherSideEdge: ["Budget"],
        risks: ["Anchor"],
        knownFacts: ["Offer mentioned"],
        assumptions: ["They can move"],
        unknowns: ["Ceiling unknown"],
        move: move,
        moveReason: "Because.",
        suggestedActions: ["Name a number"],
        suggestedResponses: ["I'm at X."],
        confidence: needsContext ? 0.15 : 0.7,
        category: .negotiation,
        usedFallbackMove: false,
        needsMoreContext: needsContext
    ).validated()
    var item = StoredAnalysis(
        id: UUID(),
        createdAt: Date(),
        request: AnalysisRequest(source: .typed, text: "secret conversation 80k"),
        analysis: analysis
    )
    if let outcome {
        item.outcome = MoveOutcomeRecord(
            result: outcome,
            recordedAt: Date(),
            lesson: OutcomeLesson.copy(move: move, outcome: outcome, category: .negotiation)
        )
    }
    return item
}
