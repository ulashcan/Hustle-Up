import Foundation

enum SituationIntent: String, Codable, Sendable, Equatable, Hashable {
    case negotiate
    case extractInfo
    case reply
    case repair
    case decline
    case exit
    case unknown

    static func parse(_ raw: String) -> SituationIntent {
        let compact = raw
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
        switch compact {
        case "negotiate", "negotiation", "bargain":
            return .negotiate
        case "extractinfo", "extract", "clarify", "ask":
            return .extractInfo
        case "reply", "respond", "text":
            return .reply
        case "repair", "apologize", "apology":
            return .repair
        case "decline", "reject", "no":
            return .decline
        case "exit", "walk", "leave":
            return .exit
        default:
            return .unknown
        }
    }
}
