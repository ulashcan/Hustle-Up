import Foundation

enum AIResponseParser {
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func parseAnalysis(_ data: Data) throws -> SituationAnalysis {
        guard !data.isEmpty else { throw AppError.malformedAIResponse }
        if let wrapped = try? decoder.decode(Wrapper<AnalysisDTO>.self, from: data),
           let inner = wrapped.payload {
            return try enrich(inner.makeAnalysis())
        }
        if let direct = try? decoder.decode(AnalysisDTO.self, from: data) {
            return try enrich(direct.makeAnalysis())
        }
        throw AppError.malformedAIResponse
    }

    static func parseFumble(_ data: Data) throws -> FumbleCheckResult {
        guard !data.isEmpty else { throw AppError.malformedAIResponse }
        if let wrapped = try? decoder.decode(Wrapper<FumbleDTO>.self, from: data),
           let inner = wrapped.payload {
            return try inner.makeResult()
        }
        if let direct = try? decoder.decode(FumbleDTO.self, from: data) {
            return try direct.makeResult()
        }
        throw AppError.malformedAIResponse
    }

    static func parsePracticeTurn(_ data: Data) throws -> PracticeTurnResult {
        if let direct = try? decoder.decode(PracticeTurnDTO.self, from: data) {
            return try direct.makeResult()
        }
        throw AppError.malformedAIResponse
    }

    static func parseScorecard(_ data: Data) throws -> PracticeScorecard {
        if let direct = try? decoder.decode(ScorecardDTO.self, from: data) {
            return try direct.makeResult()
        }
        throw AppError.malformedAIResponse
    }

    private static func enrich(_ analysis: SituationAnalysis) throws -> SituationAnalysis {
        var copy = analysis
        if copy.intent == .unknown {
            copy.intent = IntentDetector.detect(copy.situation)
        }
        if copy.intent == .unknown {
            switch copy.category {
            case .negotiation, .offer: copy.intent = .negotiate
            case .reply: copy.intent = .reply
            case .decline: copy.intent = .decline
            case .request: copy.intent = .extractInfo
            default: break
            }
        }
        if copy.sharedInterest.isEmpty {
            copy.sharedInterest = EdgeMapBuilder.sharedInterest(category: copy.category)
        }
        if copy.moveOptions.isEmpty && !copy.needsMoreContext {
            copy.moveOptions = MoveSelector.options(primary: copy.move, category: copy.category)
        }
        return try copy.validated()
    }
}

private struct Wrapper<T: Decodable>: Decodable {
    let analysis: T?
    let data: T?
    let result: T?

    var payload: T? { analysis ?? data ?? result }
}

private struct AnalysisDTO: Decodable {
    var situation: String?
    var userEdge: [String]?
    var user_edge: [String]?
    var otherSideEdge: [String]?
    var other_side_edge: [String]?
    var theirEdge: [String]?
    var risks: [String]?
    var knownFacts: [String]?
    var known_facts: [String]?
    var assumptions: [String]?
    var unknowns: [String]?
    var unknownInformation: [String]?
    var move: String?
    var moveReason: String?
    var move_reason: String?
    var suggestedActions: [String]?
    var suggested_actions: [String]?
    var suggestedResponses: [String]?
    var suggested_responses: [String]?
    var confidence: Double?
    var category: String?
    var needsMoreContext: Bool?
    var needs_more_context: Bool?
    var missingContextQuestions: [String]?
    var missing_context_questions: [String]?

    func makeAnalysis() throws -> SituationAnalysis {
        let moveParse = MoveVerb.parse(move ?? "")
        let analysis = SituationAnalysis(
            situation: situation ?? "",
            userEdge: userEdge ?? user_edge ?? [],
            otherSideEdge: otherSideEdge ?? other_side_edge ?? theirEdge ?? [],
            risks: risks ?? [],
            knownFacts: knownFacts ?? known_facts ?? [],
            assumptions: assumptions ?? [],
            unknowns: unknowns ?? unknownInformation ?? [],
            move: moveParse ?? .ask,
            moveReason: moveReason ?? move_reason ?? "",
            suggestedActions: suggestedActions ?? suggested_actions ?? [],
            suggestedResponses: suggestedResponses ?? suggested_responses ?? [],
            confidence: confidence ?? 0.5,
            category: SituationCategory.parse(category ?? "other"),
            usedFallbackMove: moveParse == nil,
            needsMoreContext: needsMoreContext ?? needs_more_context ?? false,
            missingContextQuestions: missingContextQuestions ?? missing_context_questions ?? [],
            evidenceStrength: EvidenceStrength.resolve(
                needsMoreContext: needsMoreContext ?? needs_more_context ?? false,
                usedFallbackMove: moveParse == nil,
                confidence: confidence ?? 0.5
            )
        )
        return try analysis.validated()
    }
}

private struct FumbleDTO: Decodable {
    var verdict: String?
    var headline: String?
    var reason: String?
    var improvedMessage: String?
    var improved_message: String?

    func makeResult() throws -> FumbleCheckResult {
        let verdict = parseVerdict(verdict)
        let result = FumbleCheckResult(
            verdict: verdict,
            headline: headline ?? "",
            reason: reason ?? "",
            improvedMessage: improvedMessage ?? improved_message
        )
        return try result.validated()
    }

    private func parseVerdict(_ raw: String?) -> FumbleVerdict {
        let compact = (raw ?? "")
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
        switch compact {
        case "fumble":
            return .fumble
        case "sendit", "send":
            return .sendIt
        case "tighten", "revise", "fix":
            return .tighten
        default:
            return .tighten
        }
    }
}

private struct PracticeTurnDTO: Decodable {
    var otherPartyReply: String?
    var other_party_reply: String?
    var shouldOfferToFinish: Bool?
    var should_offer_to_finish: Bool?

    func makeResult() throws -> PracticeTurnResult {
        let reply = (otherPartyReply ?? other_party_reply ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reply.isEmpty else { throw AppError.malformedAIResponse }
        return PracticeTurnResult(
            otherPartyReply: reply,
            shouldOfferToFinish: shouldOfferToFinish ?? should_offer_to_finish ?? false
        )
    }
}

private struct ScorecardDTO: Decodable {
    var confidence: Int?
    var clarity: Int?
    var persuasion: Int?
    var strategicPositioning: Int?
    var strategic_positioning: Int?
    var strongestMistake: String?
    var strongest_mistake: String?
    var suggestedImprovement: String?
    var suggested_improvement: String?

    func makeResult() throws -> PracticeScorecard {
        let card = PracticeScorecard(
            confidence: confidence ?? 5,
            clarity: clarity ?? 5,
            persuasion: persuasion ?? 5,
            strategicPositioning: strategicPositioning ?? strategic_positioning ?? 5,
            strongestMistake: strongestMistake ?? strongest_mistake ?? "",
            suggestedImprovement: suggestedImprovement ?? suggested_improvement ?? ""
        )
        return try card.validated()
    }
}
