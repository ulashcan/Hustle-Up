import Foundation

struct SituationAnalysis: Codable, Sendable, Equatable, Hashable {
    var situation: String
    var userEdge: [String]
    var otherSideEdge: [String]
    var risks: [String]
    var knownFacts: [String]
    var assumptions: [String]
    var unknowns: [String]
    var move: MoveVerb
    var moveReason: String
    var suggestedActions: [String]
    var suggestedResponses: [String]
    var confidence: Double
    var category: SituationCategory
    var usedFallbackMove: Bool
    var needsMoreContext: Bool
    var missingContextQuestions: [String]
    var evidenceStrength: EvidenceStrength
    var intent: SituationIntent
    var sharedInterest: [String]
    var moveOptions: [MoveOption]

    enum CodingKeys: String, CodingKey {
        case situation, userEdge, otherSideEdge, risks, knownFacts, assumptions, unknowns
        case move, moveReason, suggestedActions, suggestedResponses, confidence, category
        case usedFallbackMove, needsMoreContext, missingContextQuestions, evidenceStrength
        case intent, sharedInterest, moveOptions
    }

    var resolvedMoveOptions: [MoveOption] {
        if !moveOptions.isEmpty { return moveOptions }
        if needsMoreContext { return [] }
        return MoveSelector.options(primary: move, category: category)
    }

    var alternativeMoves: [MoveOption] {
        resolvedMoveOptions.filter { !$0.isRecommended && $0.move != move }
    }

    init(
        situation: String,
        userEdge: [String],
        otherSideEdge: [String],
        risks: [String],
        knownFacts: [String],
        assumptions: [String],
        unknowns: [String],
        move: MoveVerb,
        moveReason: String,
        suggestedActions: [String],
        suggestedResponses: [String],
        confidence: Double,
        category: SituationCategory,
        usedFallbackMove: Bool,
        needsMoreContext: Bool = false,
        missingContextQuestions: [String] = [],
        evidenceStrength: EvidenceStrength = .likely,
        intent: SituationIntent = .unknown,
        sharedInterest: [String] = [],
        moveOptions: [MoveOption] = []
    ) {
        self.situation = situation
        self.userEdge = userEdge
        self.otherSideEdge = otherSideEdge
        self.risks = risks
        self.knownFacts = knownFacts
        self.assumptions = assumptions
        self.unknowns = unknowns
        self.move = move
        self.moveReason = moveReason
        self.suggestedActions = suggestedActions
        self.suggestedResponses = suggestedResponses
        self.confidence = confidence
        self.category = category
        self.usedFallbackMove = usedFallbackMove
        self.needsMoreContext = needsMoreContext
        self.missingContextQuestions = missingContextQuestions
        self.evidenceStrength = evidenceStrength
        self.intent = intent
        self.sharedInterest = sharedInterest
        self.moveOptions = moveOptions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        situation = try c.decode(String.self, forKey: .situation)
        userEdge = try c.decodeIfPresent([String].self, forKey: .userEdge) ?? []
        otherSideEdge = try c.decodeIfPresent([String].self, forKey: .otherSideEdge) ?? []
        risks = try c.decodeIfPresent([String].self, forKey: .risks) ?? []
        knownFacts = try c.decodeIfPresent([String].self, forKey: .knownFacts) ?? []
        assumptions = try c.decodeIfPresent([String].self, forKey: .assumptions) ?? []
        unknowns = try c.decodeIfPresent([String].self, forKey: .unknowns) ?? []
        move = try c.decode(MoveVerb.self, forKey: .move)
        moveReason = try c.decodeIfPresent(String.self, forKey: .moveReason) ?? ""
        suggestedActions = try c.decodeIfPresent([String].self, forKey: .suggestedActions) ?? []
        suggestedResponses = try c.decodeIfPresent([String].self, forKey: .suggestedResponses) ?? []
        confidence = try c.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.5
        category = try c.decodeIfPresent(SituationCategory.self, forKey: .category) ?? .other
        usedFallbackMove = try c.decodeIfPresent(Bool.self, forKey: .usedFallbackMove) ?? false
        needsMoreContext = try c.decodeIfPresent(Bool.self, forKey: .needsMoreContext) ?? false
        missingContextQuestions = try c.decodeIfPresent([String].self, forKey: .missingContextQuestions) ?? []
        evidenceStrength = try c.decodeIfPresent(EvidenceStrength.self, forKey: .evidenceStrength)
            ?? EvidenceStrength.resolve(
                needsMoreContext: needsMoreContext,
                usedFallbackMove: usedFallbackMove,
                confidence: confidence
            )
        intent = try c.decodeIfPresent(SituationIntent.self, forKey: .intent) ?? .unknown
        sharedInterest = try c.decodeIfPresent([String].self, forKey: .sharedInterest) ?? []
        moveOptions = try c.decodeIfPresent([MoveOption].self, forKey: .moveOptions) ?? []
    }

    func validated() throws -> SituationAnalysis {
        let trimmed = situation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.malformedAIResponse }
        var copy = self
        copy.situation = trimmed
        copy.confidence = min(max(confidence, 0), 1)
        if usedFallbackMove {
            copy.confidence = min(copy.confidence, 0.4)
        }
        copy.userEdge = Self.sanitized(userEdge)
        copy.otherSideEdge = Self.sanitized(otherSideEdge)
        copy.risks = Self.sanitized(risks)
        copy.knownFacts = Self.sanitized(knownFacts)
        copy.assumptions = Self.sanitized(assumptions)
        copy.unknowns = Self.sanitized(unknowns)
        copy.suggestedActions = Self.sanitized(suggestedActions)
        copy.suggestedResponses = Self.sanitized(suggestedResponses)
        copy.missingContextQuestions = Self.sanitized(missingContextQuestions)
        copy.sharedInterest = Self.sanitized(sharedInterest)
        copy.moveOptions = moveOptions.filter {
            !$0.purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        copy.moveReason = moveReason.trimmingCharacters(in: .whitespacesAndNewlines)
        if copy.moveReason.isEmpty {
            copy.moveReason = copy.move.blurb
        }
        copy.evidenceStrength = EvidenceStrength.resolve(
            needsMoreContext: copy.needsMoreContext,
            usedFallbackMove: copy.usedFallbackMove,
            confidence: copy.confidence
        )
        return copy
    }

    private static func sanitized(_ items: [String]) -> [String] {
        items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

enum SuggestedCopy {
    static func isSendable(_ line: String) -> Bool {
        !line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("(don't send")
    }

    static func hasPlaceholder(_ line: String) -> Bool {
        line.contains("[") && line.contains("]")
    }

    static func primarySendable(_ lines: [String]) -> String? {
        lines.first { isSendable($0) }
    }

    static func holdLine(_ lines: [String]) -> String? {
        guard primarySendable(lines) == nil else { return nil }
        return lines.first
    }
}
