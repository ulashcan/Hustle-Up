import Foundation

protocol AIServicing: Sendable {
    func analyze(input: AnalysisRequest) async throws -> SituationAnalysis
    func checkFumble(message: String, context: FumbleContext) async throws -> FumbleCheckResult
    func practiceTurn(session: PracticeSession, userMessage: String) async throws -> PracticeTurnResult
    func scorePractice(session: PracticeSession) async throws -> PracticeScorecard
}
