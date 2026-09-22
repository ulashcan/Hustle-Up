import Foundation

enum PracticeRole: String, Codable, Sendable, Equatable, Hashable {
    case user
    case other
}

struct PracticeTurn: Codable, Sendable, Equatable, Identifiable, Hashable {
    let id: UUID
    var role: PracticeRole
    var text: String
}

struct PracticeSession: Codable, Sendable, Equatable, Identifiable, Hashable {
    let id: UUID
    var scenario: String
    var otherPartyRole: String
    var turns: [PracticeTurn]
    var isComplete: Bool

    var userTurnCount: Int {
        turns.filter { $0.role == .user }.count
    }
}

struct PracticeTurnResult: Codable, Sendable, Equatable, Hashable {
    var otherPartyReply: String
    var shouldOfferToFinish: Bool
}

struct PracticeScorecard: Codable, Sendable, Equatable, Hashable {
    var confidence: Int
    var clarity: Int
    var persuasion: Int
    var strategicPositioning: Int
    var leveragePreservation: Int
    var timing: Int
    var riskManagement: Int
    var strongestMistake: String
    var suggestedImprovement: String
    var whatYouDid: String
    var whatWorked: String
    var whatHurt: String
    var nextMove: String

    enum CodingKeys: String, CodingKey {
        case confidence, clarity, persuasion, strategicPositioning
        case leveragePreservation, timing, riskManagement
        case strongestMistake, suggestedImprovement
        case whatYouDid, whatWorked, whatHurt, nextMove
    }

    init(
        confidence: Int,
        clarity: Int,
        persuasion: Int,
        strategicPositioning: Int,
        leveragePreservation: Int = 5,
        timing: Int = 5,
        riskManagement: Int = 5,
        strongestMistake: String,
        suggestedImprovement: String,
        whatYouDid: String = "",
        whatWorked: String = "",
        whatHurt: String = "",
        nextMove: String = ""
    ) {
        self.confidence = confidence
        self.clarity = clarity
        self.persuasion = persuasion
        self.strategicPositioning = strategicPositioning
        self.leveragePreservation = leveragePreservation
        self.timing = timing
        self.riskManagement = riskManagement
        self.strongestMistake = strongestMistake
        self.suggestedImprovement = suggestedImprovement
        self.whatYouDid = whatYouDid
        self.whatWorked = whatWorked
        self.whatHurt = whatHurt
        self.nextMove = nextMove
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        confidence = try c.decode(Int.self, forKey: .confidence)
        clarity = try c.decode(Int.self, forKey: .clarity)
        persuasion = try c.decode(Int.self, forKey: .persuasion)
        strategicPositioning = try c.decode(Int.self, forKey: .strategicPositioning)
        leveragePreservation = try c.decodeIfPresent(Int.self, forKey: .leveragePreservation) ?? 5
        timing = try c.decodeIfPresent(Int.self, forKey: .timing) ?? 5
        riskManagement = try c.decodeIfPresent(Int.self, forKey: .riskManagement) ?? 5
        strongestMistake = try c.decode(String.self, forKey: .strongestMistake)
        suggestedImprovement = try c.decode(String.self, forKey: .suggestedImprovement)
        whatYouDid = try c.decodeIfPresent(String.self, forKey: .whatYouDid) ?? ""
        whatWorked = try c.decodeIfPresent(String.self, forKey: .whatWorked) ?? ""
        whatHurt = try c.decodeIfPresent(String.self, forKey: .whatHurt) ?? ""
        nextMove = try c.decodeIfPresent(String.self, forKey: .nextMove) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(confidence, forKey: .confidence)
        try c.encode(clarity, forKey: .clarity)
        try c.encode(persuasion, forKey: .persuasion)
        try c.encode(strategicPositioning, forKey: .strategicPositioning)
        try c.encode(leveragePreservation, forKey: .leveragePreservation)
        try c.encode(timing, forKey: .timing)
        try c.encode(riskManagement, forKey: .riskManagement)
        try c.encode(strongestMistake, forKey: .strongestMistake)
        try c.encode(suggestedImprovement, forKey: .suggestedImprovement)
        try c.encode(whatYouDid, forKey: .whatYouDid)
        try c.encode(whatWorked, forKey: .whatWorked)
        try c.encode(whatHurt, forKey: .whatHurt)
        try c.encode(nextMove, forKey: .nextMove)
    }

    func validated() throws -> PracticeScorecard {
        func clamp(_ value: Int) -> Int { min(max(value, 1), 10) }
        let mistake = strongestMistake.trimmingCharacters(in: .whitespacesAndNewlines)
        let improvement = suggestedImprovement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mistake.isEmpty, !improvement.isEmpty else { throw AppError.malformedAIResponse }
        let did = whatYouDid.trimmingCharacters(in: .whitespacesAndNewlines)
        let worked = whatWorked.trimmingCharacters(in: .whitespacesAndNewlines)
        let hurt = whatHurt.trimmingCharacters(in: .whitespacesAndNewlines)
        let next = nextMove.trimmingCharacters(in: .whitespacesAndNewlines)
        return PracticeScorecard(
            confidence: clamp(confidence),
            clarity: clamp(clarity),
            persuasion: clamp(persuasion),
            strategicPositioning: clamp(strategicPositioning),
            leveragePreservation: clamp(leveragePreservation),
            timing: clamp(timing),
            riskManagement: clamp(riskManagement),
            strongestMistake: mistake,
            suggestedImprovement: improvement,
            whatYouDid: did.isEmpty ? "You practiced the exchange." : did,
            whatWorked: worked.isEmpty ? "You stayed in the conversation." : worked,
            whatHurt: hurt.isEmpty ? mistake : hurt,
            nextMove: next.isEmpty ? improvement : next
        )
    }
}
