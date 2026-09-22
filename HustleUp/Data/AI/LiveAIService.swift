import Foundation

struct LiveAIService: AIServicing {
    var endpoint: URL
    var apiKey: String?
    var session: URLSession
    var timeout: TimeInterval

    init(
        endpoint: URL,
        apiKey: String? = ProcessInfo.processInfo.environment["HUSTLEUP_AI_KEY"],
        session: URLSession = .shared,
        timeout: TimeInterval = 30
    ) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.session = session
        self.timeout = timeout
    }

    static func configured() -> LiveAIService? {
        guard let raw = ProcessInfo.processInfo.environment["HUSTLEUP_AI_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw)
        else {
            return nil
        }
        return LiveAIService(endpoint: url)
    }

    func analyze(input: AnalysisRequest) async throws -> SituationAnalysis {
        let payload = Payload(
            task: "analyze",
            text: input.text,
            source: input.source.rawValue,
            message: nil,
            session: nil
        )
        let data = try await post(payload)
        return try AIResponseParser.parseAnalysis(data)
    }

    func checkFumble(message: String, context: FumbleContext) async throws -> FumbleCheckResult {
        let payload = Payload(
            task: "fumble",
            text: context.situationText,
            source: "fumble",
            message: message,
            session: nil
        )
        let data = try await post(payload)
        return try AIResponseParser.parseFumble(data)
    }

    func practiceTurn(session: PracticeSession, userMessage: String) async throws -> PracticeTurnResult {
        let payload = Payload(
            task: "practice_turn",
            text: userMessage,
            source: "practice",
            message: userMessage,
            session: session
        )
        let data = try await post(payload)
        return try AIResponseParser.parsePracticeTurn(data)
    }

    func scorePractice(session: PracticeSession) async throws -> PracticeScorecard {
        let payload = Payload(
            task: "practice_score",
            text: session.scenario,
            source: "practice",
            message: nil,
            session: session
        )
        let data = try await post(payload)
        return try AIResponseParser.parseScorecard(data)
    }

    private func post(_ payload: Payload) async throws -> Data {
        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw AppError.timedOut
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
                throw AppError.networkUnavailable
            default:
                throw AppError.networkUnavailable
            }
        } catch {
            throw AppError.networkUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }
        switch http.statusCode {
        case 200...299:
            guard !data.isEmpty else { throw AppError.malformedAIResponse }
            return data
        case 401, 403:
            throw AppError.modelUnavailable
        case 429:
            throw AppError.rateLimited
        case 408:
            throw AppError.timedOut
        case 400, 422:
            throw AppError.malformedAIResponse
        case 500...599:
            throw AppError.modelUnavailable
        default:
            throw AppError.modelUnavailable
        }
    }
}

private struct Payload: Encodable {
    var task: String
    var text: String
    var source: String
    var message: String?
    var session: PracticeSession?
}
