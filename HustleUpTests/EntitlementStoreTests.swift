import Foundation
import Testing
@testable import HustleUp

@MainActor
struct EntitlementStoreTests {
    @Test func freeLimitBlocksFourthAnalysis() throws {
        let defaults = UserDefaults(suiteName: "hu.ent.\(UUID().uuidString)")!
        let store = EntitlementStore(defaults: defaults)
        try store.consumeAnalysis()
        try store.consumeAnalysis()
        try store.consumeAnalysis()
        #expect(store.remainingFreeAnalyses == 0)
        #expect(throws: AppError.paywallRequired(.analysis)) {
            try store.consumeAnalysis()
        }
    }

    @Test func fumbleAndPracticeAreProOnly() {
        let defaults = UserDefaults(suiteName: "hu.ent.\(UUID().uuidString)")!
        let store = EntitlementStore(defaults: defaults)
        #expect(store.canUse(.fumbleCheck) == false)
        #expect(store.canUse(.practice) == false)
        store.setProPreview(true)
        #expect(store.canUse(.fumbleCheck))
        #expect(store.canUse(.practice))
        #expect(store.remainingFreeAnalyses == Int.max)
    }

    @Test func resetClearsUsage() throws {
        let defaults = UserDefaults(suiteName: "hu.ent.\(UUID().uuidString)")!
        let store = EntitlementStore(defaults: defaults)
        try store.consumeAnalysis()
        store.resetAll()
        #expect(store.analysesUsed == 0)
        #expect(store.isPro == false)
    }
}

@MainActor
struct FileAnalysisStoreTests {
    @Test func persistsWithoutImageBytes() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("store-\(UUID().uuidString).json")
        let store = FileAnalysisStore(fileURL: url, cap: 2)
        let analysis = try SituationAnalysis(
            situation: "Offer on the table.",
            userEdge: ["Walk"],
            otherSideEdge: ["Budget"],
            risks: ["Anchor"],
            knownFacts: ["Offer mentioned"],
            assumptions: ["They can move"],
            unknowns: ["Ceiling unknown"],
            move: .counter,
            moveReason: "Counter.",
            suggestedActions: ["Name a number"],
            suggestedResponses: ["I'm at X."],
            confidence: 0.7,
            category: .negotiation,
            usedFallbackMove: false
        ).validated()
        let item = StoredAnalysis(
            id: UUID(),
            createdAt: Date(),
            request: AnalysisRequest(source: .typed, text: "they offered 80k"),
            analysis: analysis
        )
        store.append(item)
        store.append(item)
        store.append(item)
        #expect(store.items.count == 2)
        let data = try Data(contentsOf: url)
        let raw = String(decoding: data, as: UTF8.self)
        #expect(!raw.contains("pngData"))
        #expect(!raw.contains("\"image\""))
        #expect(raw.contains("Offer on the table."))

        let reloaded = FileAnalysisStore(fileURL: url, cap: 2)
        #expect(reloaded.items.count == 2)
        #expect(reloaded.items.first?.analysis.situation == "Offer on the table.")
    }
}

struct AnalyticsContractTests {
    @Test func parametersHaveNoMessageField() {
        let params = AnalyticsParameters.analysis(
            SituationAnalysis(
                situation: "secret conversation",
                userEdge: [],
                otherSideEdge: [],
                risks: [],
                knownFacts: [],
                assumptions: [],
                unknowns: [],
                move: .wait,
                moveReason: "Wait.",
                suggestedActions: [],
                suggestedResponses: [],
                confidence: 0.5,
                category: .reply,
                usedFallbackMove: false
            )
        )
        #expect(params.category == "reply")
        #expect(params.move == "WAIT")
        #expect(params.source == nil)
    }
}
