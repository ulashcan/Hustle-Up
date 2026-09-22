import Foundation

enum MoveOutcome: String, Codable, Sendable, Equatable, Hashable, CaseIterable, Identifiable {
    case yes
    case no
    case partly
    case notSure

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yes: "YES"
        case .no: "NO"
        case .partly: "PARTLY"
        case .notSure: "NOT SURE"
        }
    }

    var sampleLabel: String {
        displayName
    }
}

struct MoveOutcomeRecord: Codable, Sendable, Equatable, Hashable {
    var result: MoveOutcome
    var recordedAt: Date
    var lesson: String
}

enum OutcomeLesson {
    static func copy(move: MoveVerb, outcome: MoveOutcome, category: SituationCategory) -> String {
        _ = category
        switch (move, outcome) {
        case (.counter, .yes):
            return "The counter landed. Keep the next number clean."
        case (.counter, .no):
            return "The counter didn't land. Next time, one question before another number."
        case (.wait, .yes):
            return "Waiting worked. You didn't need speed."
        case (.wait, .no):
            return "Waiting didn't get you what you wanted. A short ASK may have been cheaper."
        case (.ask, .yes):
            return "The question unlocked something. That's the standard."
        case (.ask, .no):
            return "The question didn't move it. Check whether you asked for a fact or for permission."
        case (.send, .yes):
            return "The short send closed the loop."
        case (.send, .no):
            return "The send didn't land. Next time, WAIT or ASK before another paragraph."
        case (.walk, .yes):
            return "Walking held. Don't reopen it."
        case (.walk, .no):
            return "Walking didn't feel like a win. That's data, not a reason to crawl back today."
        case (_, .partly):
            return "Partial. Don't treat it as a full yes or a full no."
        case (_, .notSure):
            return "Too early to call. Don't rewrite the move from a maybe."
        }
    }
}
