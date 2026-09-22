import Foundation

enum EdgeMapBuilder {
    static func sharedInterest(category: SituationCategory) -> [String] {
        switch category {
        case .negotiation, .offer:
            return ["POSSIBLE. Both still want a deal that can close. Unverified."]
        case .conflict:
            return ["POSSIBLE. You still share a relationship. Unverified."]
        case .request:
            return ["POSSIBLE. They asked; you haven't answered. That's not a yes from either side."]
        default:
            return []
        }
    }
}
