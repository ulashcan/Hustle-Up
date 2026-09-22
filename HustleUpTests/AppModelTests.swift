import Foundation
import Testing
@testable import HustleUp

struct MockAIServiceTests {
    @Test func salaryLooksLikeNegotiationAndDoesNotInventARate() async throws {
        let ai = MockAIService(delay: .zero)
        let analysis = try await ai.analyze(
            input: AnalysisRequest(source: .typed, text: "My boss made an offer for a raise. Should I take 90k?")
        )
        #expect(analysis.category == .negotiation || analysis.category == .offer)
        #expect(analysis.move == .counter || analysis.move == .ask)
        #expect(analysis.unknowns.contains { $0.lowercased().contains("unknown") })
        let joined = (analysis.knownFacts + [analysis.situation]).joined(separator: " ").lowercased()
        #expect(!joined.contains("market average"))
        #expect(!joined.contains("percentile"))
    }

    @Test func fumbleCatchesSelfNegotiation() async throws {
        let ai = MockAIService(delay: .zero)
        let result = try await ai.checkFumble(
            message: "Sorry I can go lower or whatever you think is fair whenever you want",
            context: FumbleContext(situationText: "rate talk", recommendedMove: .counter)
        )
        #expect(result.verdict == .fumble)
        #expect(result.improvedMessage != nil)
    }

    @Test func shortCleanMessageSends() async throws {
        let ai = MockAIService(delay: .zero)
        let result = try await ai.checkFumble(
            message: "I'm at 12k, net 30.",
            context: FumbleContext(situationText: "invoice", recommendedMove: .send)
        )
        #expect(result.verdict == .sendIt)
    }
}

@MainActor
struct AppModelTests {
    @Test func emptyComposeDoesNotCallAI() async {
        let (model, analytics) = TestAppFactory.model()
        model.composeText = "   "
        await model.analyzeCurrentInput()
        #expect(model.error == .emptyInput)
        #expect(model.analysis == nil)
        #expect(!analytics.records.contains { $0.event == .analysisStarted })
    }

    @Test func successfulAnalysisShowsMove() async {
        let (model, analytics) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the project."
        await model.analyzeCurrentInput()
        #expect(model.error == nil)
        #expect(model.analysis?.analysis.move != nil)
        #expect(model.path.contains(.analysis))
        #expect(analytics.records.contains { $0.event == .moveViewed })
    }

    @Test func fourthFreeAnalysisPresentsPaywall() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        model.path = []
        await model.analyzeCurrentInput()
        model.path = []
        await model.analyzeCurrentInput()
        model.path = []
        await model.analyzeCurrentInput()
        #expect(model.showPaywall)
        #expect(model.paywallFeature == .analysis)
    }

    @Test func fumbleIsGatedWithoutPro() {
        let (model, analytics) = TestAppFactory.model(pro: false)
        model.openFumble()
        #expect(model.showPaywall)
        #expect(model.paywallFeature == .fumbleCheck)
        #expect(analytics.records.contains { $0.event == .paywallViewed })
        #expect(!model.path.contains(.fumble))
    }

    @Test func practiceRunsWhenPro() async {
        let (model, analytics) = TestAppFactory.model(pro: true)
        model.composeText = "I want to ask my boss for a raise."
        await model.analyzeCurrentInput()
        model.openPractice()
        #expect(model.path.contains(.practice))
        model.practiceDraft = "I've taken on two extra teams this year. I'm asking for 15%."
        await model.sendPracticeTurn()
        #expect(model.practice?.turns.count == 2)
        await model.finishPractice()
        #expect(model.scorecard != nil)
        #expect(analytics.records.contains { $0.event == .practiceCompleted })
    }

    @Test func networkFailureIsRecoverable() async {
        let (model, analytics) = TestAppFactory.model(ai: FailingAIService(error: .networkUnavailable))
        model.composeText = "We're having an argument."
        await model.analyzeCurrentInput()
        #expect(model.error == .networkUnavailable)
        #expect(analytics.records.contains { $0.event == .analysisFailed })
    }

    @Test func malformedAIIsRecoverable() async {
        let (model, _) = TestAppFactory.model(ai: MalformedPayloadAIService())
        model.composeText = "We're having an argument about the meeting and I already drafted a long reply."
        await model.analyzeCurrentInput()
        #expect(model.error == .malformedAIResponse)
    }

    @Test func screenshotWithoutTextLandsOnReview() async {
        let emptyOCR = StubOCRService(
            result: OCRResult(rawText: "", cleanedText: "", confidence: 0, observationCount: 0, wasTruncated: false),
            error: nil
        )
        let (model, _) = TestAppFactory.model(ocr: emptyOCR)
        let image = TestImageFactory.png(width: 200, height: 200, checkerboard: true)
        await model.importImageData(image)
        #expect(model.path.contains(.ocrReview))
        #expect(model.error == nil)
        #expect(model.canAnalyzeCurrentInput == false)
        #expect(model.ocrResult?.isEmpty == true)
    }

    @Test func uiTestingEmptyOCROpensReviewWithoutABanner() {
        let (model, _) = TestAppFactory.model(arguments: ["-ui-testing", "-empty-ocr"])
        #expect(model.path.contains(.ocrReview))
        #expect(model.error == nil)
        #expect(model.canAnalyzeCurrentInput == false)
        #expect(model.ocrResult?.isEmpty == true)
    }

    @Test func emptyScreenshotIsRejected() async {
        let (model, _) = TestAppFactory.model()
        let image = TestImageFactory.png(width: 180, height: 180, checkerboard: false, solid: 8)
        await model.importImageData(image)
        #expect(model.error == .imageEmpty)
        #expect(!model.path.contains(.ocrReview))
    }

    @Test func failedAnalysisDoesNotBurnACredit() async {
        let (model, _) = TestAppFactory.model(ai: FailingAIService(error: .networkUnavailable))
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        #expect(model.environment.entitlements.analysesUsed == 0)
        #expect(model.showPaywall == false)
    }

    @Test func thinInputDoesNotConsumeOrPersist() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Should I reply?"
        await model.analyzeCurrentInput()
        #expect(model.analysis?.analysis.needsMoreContext == true)
        #expect(model.environment.entitlements.analysesUsed == 0)
        #expect(model.environment.store.items.isEmpty)
        #expect(model.path.contains(.analysis))
    }

    @Test func retryReplaysAnalyzeAfterNetworkFailure() async {
        let ai = FlakyAIService(failuresRemaining: 1)
        let (model, _) = TestAppFactory.model(ai: ai)
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        #expect(model.error == .timedOut)
        await model.handleErrorActionAsync()
        #expect(model.error == nil)
        #expect(model.analysis != nil)
        #expect(model.environment.entitlements.analysesUsed == 1)
    }

    @Test func cancelledErrorIsSwallowed() {
        let (model, _) = TestAppFactory.model()
        model.present(.cancelled)
        #expect(model.error == nil)
        #expect(model.showPaywall == false)
    }

    @Test func addDetailReturnsToComposeWithoutBurningCredit() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Should I reply?"
        await model.analyzeCurrentInput()
        #expect(model.analysis?.analysis.needsMoreContext == true)
        model.addDetail()
        #expect(!model.path.contains(.analysis))
        #expect(model.path.contains(.compose))
        #expect(model.environment.entitlements.analysesUsed == 0)
    }

    @Test func failedPracticeTurnDoesNotDropTheDraft() async {
        let ai = FlakyAIService(failuresRemaining: 0)
        let (model, _) = TestAppFactory.model(ai: ai, pro: true)
        model.composeText = "I want to ask my boss for a raise next week after the review."
        await model.analyzeCurrentInput()
        model.openPractice()
        ai.setFailures(1)
        model.practiceDraft = "I've owned two extra teams. I'm asking for 15 percent."
        await model.sendPracticeTurn()
        #expect(model.error == .timedOut)
        #expect(model.practice?.turns.isEmpty == true)
        #expect(model.practiceDraft.contains("15 percent"))
        await model.handleErrorActionAsync()
        #expect(model.error == nil)
        #expect(model.practice?.turns.count == 2)
        #expect(model.practiceDraft.isEmpty)
    }

    @Test func cancellingOCRDoesNotOpenReview() async {
        let (model, _) = TestAppFactory.model(ocr: SlowOCRService())
        let image = TestImageFactory.png(width: 200, height: 200, checkerboard: true)
        let task = Task { await model.importImageData(image) }
        for _ in 0..<40 {
            if model.loading == .ocr { break }
            try? await Task.sleep(for: .milliseconds(10))
        }
        model.cancelLoading()
        await task.value
        #expect(!model.path.contains(.ocrReview))
        #expect(model.loading == nil)
    }

    @Test func goHomeKeepsLastMoveForTheSession() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        model.goHome()
        #expect(model.path.isEmpty)
        #expect(model.lastMove?.analysis.move != nil)
        #expect(model.lastMove?.analysis.needsMoreContext == false)
    }

    @Test func insufficientResultIsNotLastMove() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Should I reply?"
        await model.analyzeCurrentInput()
        model.goHome()
        #expect(model.lastMove == nil)
    }

    @Test func ignoresAnalyzeWhileAlreadyLoading() async {
        let (model, analytics) = TestAppFactory.model()
        model.loading = .analysis
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        #expect(model.analysis == nil)
        #expect(!analytics.records.contains { $0.event == .analysisStarted })
    }

    @Test func exampleChipFillsARealSeed() {
        let (model, _) = TestAppFactory.model()
        model.openCompose(example: .bossOffer)
        #expect(model.composeText.contains("90k"))
        #expect(model.path.contains(.compose))
        #expect(model.inputSource == .example)
    }

    @Test func lastMoveSurvivesInsufficientFollowUp() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        let kept = model.lastMove?.id
        #expect(kept != nil)
        model.goHome()
        model.openCompose()
        model.composeText = "Should I reply?"
        await model.analyzeCurrentInput()
        #expect(model.analysis?.analysis.needsMoreContext == true)
        model.goHome()
        #expect(model.lastMove?.id == kept)
        #expect(model.lastMove?.analysis.needsMoreContext == false)
    }

    @Test func lastMoveClearedWhenDataDeleted() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        #expect(model.lastMove != nil)
        model.deleteAllData()
        #expect(model.lastMove == nil)
    }

    @Test func openLastMoveRestoresTheSessionResult() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        let original = model.lastMove?.id
        model.goHome()
        model.composeText = "Should I reply?"
        await model.analyzeCurrentInput()
        model.goHome()
        model.openLastMove()
        #expect(model.path.contains(.analysis))
        #expect(model.analysis?.id == original)
        #expect(model.analysis?.analysis.needsMoreContext == false)
    }

    @Test func openFumbleDoesNotPrefillWaitPlaceholder() async {
        let (model, _) = TestAppFactory.model(pro: true)
        model.composeText = "We're having an argument. I already drafted a long reply."
        await model.analyzeCurrentInput()
        #expect(model.analysis?.analysis.move == .wait)
        model.openFumble()
        #expect(!model.fumbleDraft.lowercased().hasPrefix("(don't send"))
        #expect(model.path.contains(.fumble))
    }

    @Test func openFumbleDoesNotStack() async {
        let (model, _) = TestAppFactory.model(pro: true)
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        model.openFumble()
        model.openFumble()
        #expect(model.path.filter { $0 == .fumble }.count == 1)
    }

    @Test func openPracticeDoesNotStack() async {
        let (model, _) = TestAppFactory.model(pro: true)
        model.composeText = "I want to ask my boss for a raise next week after the review."
        await model.analyzeCurrentInput()
        model.openPractice()
        model.openPractice()
        #expect(model.path.filter { $0 == .practice }.count == 1)
    }

    @Test func screenshotReviewDoesNotStack() async {
        let (model, _) = TestAppFactory.model()
        let image = TestImageFactory.png(width: 200, height: 200, checkerboard: true)
        await model.importImageData(image)
        await model.importImageData(image)
        #expect(model.path.filter { $0 == .ocrReview }.count == 1)
    }

    @Test func lastMoveRestoresFromPersistedHistory() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        let id = model.lastMove?.id
        #expect(id != nil)
        let restored = AppModel(environment: model.environment)
        #expect(restored.lastMove?.id == id)
        #expect(restored.lastMove?.analysis.needsMoreContext == false)
    }

    @Test func remainingHeadlineSaysNoMovesWhenEmpty() async {
        let (model, _) = TestAppFactory.model()
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        model.path = []
        await model.analyzeCurrentInput()
        model.path = []
        await model.analyzeCurrentInput()
        #expect(model.remainingMovesHeadline == "NO MOVES LEFT")
        #expect(model.remainingAnalysesDetail == "No free analyses left")
    }

    @Test func openComposeDoesNotStackDuplicateScreens() {
        let (model, _) = TestAppFactory.model()
        model.openCompose()
        model.openCompose()
        #expect(model.path.filter { $0 == .compose }.count == 1)
    }

    @Test func typeInsteadSwitchesToTypedCompose() {
        let (model, _) = TestAppFactory.model()
        model.inputSource = .screenshot
        model.path = [.ocrReview]
        model.switchToTypedInput()
        #expect(model.inputSource == .typed)
        #expect(model.path.contains(.compose))
        #expect(model.error == nil)
    }

    @Test func sendItExposesTheDraftToCopy() async {
        let (model, _) = TestAppFactory.model(pro: true)
        model.composeText = "Client wants a discount on the remaining work this quarter."
        await model.analyzeCurrentInput()
        model.fumbleDraft = "I'm at 12k, net 30."
        await model.runFumble()
        #expect(model.fumbleResult?.verdict == .sendIt)
        #expect(model.fumbleCopyText == "I'm at 12k, net 30.")
    }
}
