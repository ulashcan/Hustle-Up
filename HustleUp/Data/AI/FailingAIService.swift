import Foundation

struct FailingAIService: AIServicing {
    var error: AppError

    func analyze(input: AnalysisRequest) async throws -> SituationAnalysis {
        _ = input
        throw error
    }

    func checkFumble(message: String, context: FumbleContext) async throws -> FumbleCheckResult {
        _ = message
        _ = context
        throw error
    }

    func practiceTurn(session: PracticeSession, userMessage: String) async throws -> PracticeTurnResult {
        _ = session
        _ = userMessage
        throw error
    }

    func scorePractice(session: PracticeSession) async throws -> PracticeScorecard {
        _ = session
        throw error
    }
}

struct MalformedPayloadAIService: AIServicing {
    func analyze(input: AnalysisRequest) async throws -> SituationAnalysis {
        _ = input
        throw AppError.malformedAIResponse
    }

    func checkFumble(message: String, context: FumbleContext) async throws -> FumbleCheckResult {
        _ = message
        _ = context
        throw AppError.malformedAIResponse
    }

    func practiceTurn(session: PracticeSession, userMessage: String) async throws -> PracticeTurnResult {
        _ = session
        _ = userMessage
        throw AppError.malformedAIResponse
    }

    func scorePractice(session: PracticeSession) async throws -> PracticeScorecard {
        _ = session
        throw AppError.malformedAIResponse
    }
}
