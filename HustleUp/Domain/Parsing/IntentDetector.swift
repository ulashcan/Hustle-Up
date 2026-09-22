import Foundation

enum IntentDetector {
    static func detect(_ text: String) -> SituationIntent {
        let t = text.lowercased()
        if matches(t, ["not interested", "leave me alone", "don't contact", "do not contact", "walk away", "i'm out"]) {
            return .exit
        }
        if matches(t, ["decline", "say no", "turn it down", "pass on this"]) {
            return .decline
        }
        if matches(t, ["i yelled", "i was wrong", "i messed up", "i owe them", "apolog"]) {
            return .repair
        }
        if matches(t, ["raise", "salary", "discount", "rate", "offer", "invoice", "lowball", "quote", "budget", "rent", "refund"]) {
            return .negotiate
        }
        if matches(t, ["what's the range", "what is the range", "who else", "timeline", "decision-maker"]) {
            return .extractInfo
        }
        if matches(t, ["should i reply", "texted", "left me on", "hang out", "double text", "message"]) {
            return .reply
        }
        return .unknown
    }

    private static func matches(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }
}
