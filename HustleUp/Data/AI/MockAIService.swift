import Foundation

struct MockAIService: AIServicing {
    var delay: Duration

    init(delay: Duration = .milliseconds(650)) {
        self.delay = delay
    }

    func analyze(input: AnalysisRequest) async throws -> SituationAnalysis {
        try await pause()
        return try SituationInterpreter.analyze(input.text)
    }

    func checkFumble(message: String, context: FumbleContext) async throws -> FumbleCheckResult {
        try await pause()
        return try FumbleEngine.check(message: message, context: context)
    }

    func practiceTurn(session: PracticeSession, userMessage: String) async throws -> PracticeTurnResult {
        try await pause()
        return try PracticeEngine.reply(session: session, userMessage: userMessage)
    }

    func scorePractice(session: PracticeSession) async throws -> PracticeScorecard {
        try await pause()
        return try PracticeEngine.score(session)
    }

    private func pause() async throws {
        guard delay != .zero else { return }
        try await Task.sleep(for: delay)
    }
}
