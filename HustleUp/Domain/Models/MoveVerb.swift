import Foundation

enum MoveVerb: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case counter = "COUNTER"
    case wait = "WAIT"
    case ask = "ASK"
    case send = "SEND"
    case walk = "WALK"

    var displayName: String { "\(rawValue)." }

    var blurb: String {
        switch self {
        case .counter: "Push back with a number or a condition. Don't absorb their frame."
        case .wait: "Do not reply yet. Silence is a move."
        case .ask: "Get information before you give any away."
        case .send: "The message is strong. Send it."
        case .walk: "Your position gets worse if you stay in this exchange."
        }
    }

    static func parse(_ raw: String) -> MoveVerb? {
        let compact = raw
            .uppercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")

        switch compact {
        case "COUNTER", "COUNTEROFFER", "PUSH", "PUSHBACK":
            return .counter
        case "WAIT", "HOLD", "PAUSE", "DONTREPLY":
            return .wait
        case "ASK", "CLARIFY", "QUESTION":
            return .ask
        case "SEND", "SENDIT", "SENDTHEMESSAGE", "ACCEPT", "TAKEIT", "DECLINE", "PASS", "FOLLOWUP", "FOLLOW":
            return .send
        case "WALK", "WALKAWAY", "LEAVE", "STOP":
            return .walk
        default:
            return nil
        }
    }
}
