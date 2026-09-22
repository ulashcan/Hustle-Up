import Foundation

enum PracticeCasting {
    static func role(scenario: String, category: SituationCategory?) -> String {
        let t = scenario.lowercased()
        if matches(t, ["landlord", "lease"]) {
            return "LANDLORD"
        }
        if matches(t, ["recruiter", "salary expectation", "comp band"]) {
            return "RECRUITER"
        }
        if matches(t, ["customer support", "support said", "refund", "charge is final"]) {
            return "CUSTOMER SUPPORT"
        }
        if matches(t, ["boss", "manager", "raise", "offer letter"]) {
            return "BOSS"
        }
        if matches(t, ["client", "freelance", "invoice", "discount"]) {
            return "CLIENT"
        }
        if matches(t, ["buyer"]) {
            return "BUYER"
        }
        if matches(t, ["coworker", "colleague"]) {
            return "COWORKER"
        }
        if matches(t, ["friend"]) {
            return "FRIEND"
        }
        if matches(t, ["family", "mom", "dad", "sister", "brother"]) {
            return "FAMILY MEMBER"
        }
        switch category {
        case .negotiation, .offer:
            return "CLIENT"
        case .conflict:
            return "COWORKER"
        case .request:
            return "THE OTHER SIDE"
        default:
            return "THE OTHER PARTY"
        }
    }

    private static func matches(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }
}
