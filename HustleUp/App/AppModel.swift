import Foundation

enum PendingRetry: Equatable {
    case analyze
    case fumble
    case practiceSend
    case practiceFinish
}

@Observable
@MainActor
final class AppModel {
    var path: [Route] = []
    var showOnboarding: Bool
    var composeText = ""
    var inputSource: InputSource = .typed
    var ocrResult: OCRResult?
    var analysis: StoredAnalysis?
    var fumbleDraft = ""
    var fumbleResult: FumbleCheckResult?
    var copiedFumble = false
    var practice: PracticeSession?
    var practiceDraft = ""
    var scorecard: PracticeScorecard?
    var loading: LoadingPhase?
    var error: AppError?
    var showPaywall = false
    var paywallFeature: Feature = .analysis
    var history: [StoredAnalysis] = []
    var lastMove: StoredAnalysis?
    var entitlementRevision = 0
    var pendingRetry: PendingRetry?

    let environment: AppEnvironment
    private var loadGeneration = 0

    var isPro: Bool {
        _ = entitlementRevision
        return environment.entitlements.isPro
    }

    var remainingFreeAnalyses: Int {
        _ = entitlementRevision
        return environment.entitlements.remainingFreeAnalyses
    }

    var canAnalyzeCurrentInput: Bool {
        !composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canRunFumble: Bool {
        !fumbleDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var fumbleCopyText: String? {
        if let improved = fumbleResult?.improvedMessage {
            let trimmed = improved.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        guard fumbleResult?.verdict == .sendIt else { return nil }
        let draft = fumbleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return draft.isEmpty ? nil : draft
    }

    var remainingMovesHeadline: String {
        switch remainingFreeAnalyses {
        case 0: return "NO MOVES LEFT"
        case 1: return "1 MOVE LEFT"
        default: return "\(remainingFreeAnalyses) MOVES LEFT"
        }
    }

    var remainingAnalysesDetail: String {
        switch remainingFreeAnalyses {
        case 0: return "No free analyses left"
        case 1: return "1 free analysis left"
        default: return "\(remainingFreeAnalyses) free analyses left"
        }
    }

    init(environment: AppEnvironment, arguments: [String] = []) {
        self.environment = environment
        let seen = UserDefaults.standard.bool(forKey: "hu.onboardingComplete")
        self.showOnboarding = environment.skipOnboardingDefault ? false : !seen
        self.history = environment.store.items
        self.lastMove = history.first { !$0.analysis.needsMoreContext }
        environment.analytics.track(.appOpen, parameters: .empty)
        applyLaunchArguments(arguments)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hu.onboardingComplete")
        showOnboarding = false
    }

    func openCompose(example: ExamplePrompt? = nil) {
        error = nil
        inputSource = example == nil ? .typed : .example
        if let example {
            composeText = example.seed
        }
        if !path.contains(.compose) {
            path.append(.compose)
        }
    }

    func switchToTypedInput() {
        error = nil
        inputSource = .typed
        if !path.contains(.compose) {
            path.append(.compose)
        }
    }

    func importImageData(_ data: Data) async {
        guard loading == nil else { return }
        error = nil
        inputSource = .screenshot
        environment.analytics.track(.screenshotSelected, parameters: .source(.screenshot))
        do {
            let validated = try environment.validator.validate(data)
            loadGeneration += 1
            let generation = loadGeneration
            loading = .ocr
            let ocr = try await environment.ocr.extractText(from: validated.pngDataForOCR)
            guard generation == loadGeneration else { return }
            ocrResult = ocr
            composeText = ocr.cleanedText
            loading = nil
            pushUnique(.ocrReview)
        } catch is CancellationError {
            loading = nil
        } catch let appError as AppError {
            loading = nil
            present(appError)
        } catch {
            loading = nil
            present(.ocrFailed)
        }
    }

    func analyzeCurrentInput() async {
        guard loading == nil else { return }
        error = nil
        let cleaned = TextCleaner.clean(composeText)
        composeText = cleaned.text
        guard !cleaned.text.isEmpty else {
            present(.emptyInput)
            return
        }
        guard environment.entitlements.canUse(.analysis) else {
            present(.paywallRequired(.analysis))
            return
        }

        pendingRetry = .analyze
        environment.analytics.track(.analysisStarted, parameters: .source(inputSource))
        loadGeneration += 1
        let generation = loadGeneration
        loading = .analysis
        do {
            let request = AnalysisRequest(
                source: inputSource,
                text: cleaned.text,
                ocrConfidence: ocrResult?.confidence,
                wasTruncated: cleaned.truncated
            )
            let result = try await environment.ai.analyze(input: request)
            guard generation == loadGeneration else { return }
            let stored = StoredAnalysis(
                id: UUID(),
                createdAt: Date(),
                request: request,
                analysis: result
            )
            if !result.needsMoreContext {
                try environment.entitlements.consumeAnalysis()
                entitlementRevision += 1
                environment.store.append(stored)
                history = environment.store.items
                lastMove = stored
            }
            analysis = stored
            fumbleDraft = ""
            fumbleResult = nil
            loading = nil
            pendingRetry = nil
            environment.analytics.track(.analysisCompleted, parameters: .analysis(result))
            environment.analytics.track(.moveViewed, parameters: .analysis(result))
            pushUnique(.analysis)
        } catch is CancellationError {
            loading = nil
        } catch let appError as AppError {
            loading = nil
            environment.analytics.track(.analysisFailed, parameters: .failure(appError))
            present(appError)
        } catch {
            loading = nil
            environment.analytics.track(.analysisFailed, parameters: .failure(.modelUnavailable))
            present(.modelUnavailable)
        }
    }

    func openFumble() {
        error = nil
        guard environment.entitlements.canUse(.fumbleCheck) else {
            present(.paywallRequired(.fumbleCheck))
            return
        }
        if fumbleDraft.isEmpty, let lines = analysis?.analysis.suggestedResponses, let candidate = SuggestedCopy.primarySendable(lines) {
            fumbleDraft = candidate
        }
        pushUnique(.fumble)
    }

    func openLastMove() {
        guard let lastMove else { return }
        openStored(lastMove)
    }

    func openProfile() {
        error = nil
        guard environment.entitlements.canUse(.history) else {
            present(.paywallRequired(.history))
            return
        }
        pushUnique(.profile)
    }

    var profileObservations: [ProfileObservation] {
        _ = entitlementRevision
        guard environment.entitlements.canUse(.history) else { return [] }
        return HustleProfileBuilder.observations(from: history)
    }

    func recordOutcome(_ result: MoveOutcome, for id: UUID? = nil) {
        error = nil
        let targetID = id ?? analysis?.id ?? lastMove?.id
        guard let targetID,
              var item = history.first(where: { $0.id == targetID }) else { return }
        guard !item.analysis.needsMoreContext else { return }
        let lesson = OutcomeLesson.copy(
            move: item.analysis.move,
            outcome: result,
            category: item.analysis.category
        )
        item.outcome = MoveOutcomeRecord(result: result, recordedAt: Date(), lesson: lesson)
        environment.store.update(item)
        history = environment.store.items
        if lastMove?.id == item.id {
            lastMove = item
        }
        if analysis?.id == item.id {
            analysis = item
        }
        environment.analytics.track(.outcomeRecorded, parameters: .outcome(result, move: item.analysis.move))
    }

    func openStored(_ item: StoredAnalysis) {
        error = nil
        analysis = item
        pushUnique(.analysis)
    }

    func runFumble() async {
        guard loading == nil else { return }
        error = nil
        let message = fumbleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else {
            present(.emptyInput)
            return
        }
        guard environment.entitlements.canUse(.fumbleCheck) else {
            present(.paywallRequired(.fumbleCheck))
            return
        }
        environment.analytics.track(.fumbleCheckStarted, parameters: .empty)
        pendingRetry = .fumble
        loading = .fumble
        do {
            let context = FumbleContext(
                situationText: analysis?.request.text ?? "",
                recommendedMove: analysis?.analysis.move
            )
            let result = try await environment.ai.checkFumble(message: message, context: context)
            fumbleResult = result
            copiedFumble = false
            loading = nil
            pendingRetry = nil
            if result.verdict == .fumble {
                environment.analytics.track(.fumbleDetected, parameters: .fumble(result))
            }
        } catch is CancellationError {
            loading = nil
        } catch let appError as AppError {
            loading = nil
            present(appError)
        } catch {
            loading = nil
            present(.modelUnavailable)
        }
    }

    func applyFumbleFix() {
        guard let improved = fumbleResult?.improvedMessage else { return }
        fumbleDraft = improved
        fumbleResult = nil
    }

    func openPractice() {
        error = nil
        guard environment.entitlements.canUse(.practice) else {
            present(.paywallRequired(.practice))
            return
        }
        let scenario = analysis?.request.text ?? composeText
        practice = PracticeSession(
            id: UUID(),
            scenario: scenario,
            otherPartyRole: otherPartyRole,
            turns: [],
            isComplete: false
        )
        practiceDraft = ""
        scorecard = nil
        environment.analytics.track(.practiceStarted, parameters: .empty)
        pushUnique(.practice)
    }

    func sendPracticeTurn() async {
        guard loading == nil else { return }
        error = nil
        guard var session = practice else { return }
        let message = practiceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else {
            present(.emptyInput)
            return
        }
        pendingRetry = .practiceSend
        loading = .practice
        do {
            let result = try await environment.ai.practiceTurn(session: session, userMessage: message)
            session.turns.append(PracticeTurn(id: UUID(), role: .user, text: message))
            session.turns.append(PracticeTurn(id: UUID(), role: .other, text: result.otherPartyReply))
            practice = session
            practiceDraft = ""
            loading = nil
            pendingRetry = nil
        } catch is CancellationError {
            loading = nil
        } catch let appError as AppError {
            loading = nil
            present(appError)
        } catch {
            loading = nil
            present(.modelUnavailable)
        }
    }

    func finishPractice() async {
        guard loading == nil else { return }
        error = nil
        guard var session = practice, session.userTurnCount >= 1 else {
            present(.emptyInput)
            return
        }
        pendingRetry = .practiceFinish
        loading = .practice
        do {
            let card = try await environment.ai.scorePractice(session: session)
            session.isComplete = true
            practice = session
            scorecard = card
            loading = nil
            pendingRetry = nil
            environment.analytics.track(.practiceCompleted, parameters: .empty)
            pushUnique(.scorecard)
        } catch is CancellationError {
            loading = nil
        } catch let appError as AppError {
            loading = nil
            present(appError)
        } catch {
            loading = nil
            present(.modelUnavailable)
        }
    }

    func tryPracticeAgain() {
        scorecard = nil
        practiceDraft = ""
        if var session = practice {
            session.turns = []
            session.isComplete = false
            practice = session
        }
        path.removeAll { $0 == .scorecard }
    }

    func addDetail() {
        error = nil
        path.removeAll { $0 == .analysis }
        if !path.contains(.compose) && !path.contains(.ocrReview) {
            path.append(.compose)
        }
    }

    func cancelLoading() {
        loadGeneration += 1
        loading = nil
    }

    func goHome() {
        cancelLoading()
        path = []
        error = nil
        fumbleResult = nil
        copiedFumble = false
        practiceDraft = ""
    }

    func present(_ appError: AppError) {
        if case .paywallRequired(let feature) = appError {
            paywallFeature = feature
            showPaywall = true
            environment.analytics.track(.paywallViewed, parameters: .feature(feature))
            return
        }
        if appError == .cancelled { return }
        error = appError
    }

    func handleErrorAction() {
        Task { await handleErrorActionAsync() }
    }

    func handleErrorActionAsync() async {
        guard let error else { return }
        switch error {
        case .imageTooSmall, .imageEmpty, .imageUnsupported, .ocrFailed, .noTextDetected:
            self.error = nil
            if !path.contains(.compose) {
                path.append(.compose)
            }
        case .paywallRequired:
            self.error = nil
            showPaywall = true
        case .networkUnavailable, .timedOut, .malformedAIResponse, .modelUnavailable, .rateLimited:
            let retry = pendingRetry
            self.error = nil
            switch retry {
            case .analyze:
                await analyzeCurrentInput()
            case .fumble:
                await runFumble()
            case .practiceSend:
                await sendPracticeTurn()
            case .practiceFinish:
                await finishPractice()
            case nil:
                break
            }
        default:
            self.error = nil
        }
    }

    func enableProPreview() {
        setProPreview(true)
        environment.analytics.track(.subscriptionStarted, parameters: .empty)
        showPaywall = false
    }

    func setProPreview(_ enabled: Bool) {
        environment.entitlements.setProPreview(enabled)
        entitlementRevision += 1
    }

    func deleteAllData() {
        environment.store.deleteAll()
        environment.entitlements.resetAll()
        entitlementRevision += 1
        history = []
        analysis = nil
        lastMove = nil
        ocrResult = nil
        composeText = ""
        fumbleDraft = ""
        fumbleResult = nil
        practice = nil
        scorecard = nil
        path = []
    }

    private var otherPartyRole: String {
        PracticeCasting.role(
            scenario: analysis?.request.text ?? composeText,
            category: analysis?.analysis.category
        )
    }

    private func pushUnique(_ route: Route) {
        if !path.contains(route) {
            path.append(route)
        }
    }

    private func applyLaunchArguments(_ arguments: [String]) {
        guard arguments.contains("-ui-testing") else { return }
        if arguments.contains("-empty-ocr") {
            ocrResult = OCRResult(
                rawText: "",
                cleanedText: "",
                confidence: 0,
                observationCount: 0,
                wasTruncated: false
            )
            composeText = ""
            inputSource = .screenshot
            path = [.ocrReview]
        }
    }
}
