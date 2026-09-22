import Foundation

enum SituationCategory: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case negotiation
    case conflict
    case reply
    case offer
    case request
    case decline
    case other

    static func parse(_ raw: String) -> SituationCategory {
        let compact = raw
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
        switch compact {
        case "negotiation", "salary", "pricing", "deal":
            return .negotiation
        case "conflict", "argument", "fight":
            return .conflict
        case "reply", "text", "message":
            return .reply
        case "offer":
            return .offer
        case "request", "ask":
            return .request
        case "decline", "rejection", "no":
            return .decline
        default:
            return .other
        }
    }
}
