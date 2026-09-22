import Foundation

struct ContextAssessment: Equatable, Sendable {
    var isSufficient: Bool
    var missing: [String]
}

enum ContextGate {
    private static let actors = [
        "boss", "manager", "client", "coworker", "colleague", "they", "she", "he",
        "them", "landlord", "buyer", "recruiter", "founder", "we ", "we're", "we’re"
    ]

    private static let stakes = [
        "offer", "raise", "salary", "discount", "price", "rate", "rent", "invoice",
        "argument", "fight", "text", "message", "reply", "respond", "date", "hang",
        "ghost", "lowball", "budget", "quote", "deal", "contract", "comp", "freelance"
    ]

    static func assess(_ raw: String) -> ContextAssessment {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        let wordCount = lower.split { $0.isWhitespace || $0.isNewline }.count

        let hasActor = actors.contains { lower.contains($0) }
        let hasStake = stakes.contains { lower.contains($0) }

        if wordCount == 0 {
            return ContextAssessment(
                isSufficient: false,
                missing: ["Who is on the other side?", "What was actually said?", "What do you want?"]
            )
        }

        let bareQuestion = matches(lower, [
            "should i send",
            "should i reply",
            "should i text",
            "should i respond",
            "what do i do",
            "what's the move",
            "whats the move"
        ])
        if bareQuestion && wordCount < 12 && !hasStake {
            return ContextAssessment(
                isSufficient: false,
                missing: [
                    "Who is on the other side?",
                    "What was actually said?",
                    "What do you want next?"
                ]
            )
        }

        let bareReply = (lower.contains("reply") || lower.contains("respond"))
            && wordCount < 8
            && !hasActor
        if bareReply {
            return ContextAssessment(
                isSufficient: false,
                missing: [
                    "Who wrote to you?",
                    "What did they actually say?",
                    "What outcome do you want?"
                ]
            )
        }

        if wordCount < 3 {
            return ContextAssessment(
                isSufficient: false,
                missing: [
                    "Who is involved?",
                    "What just happened?",
                    "What do you want next?"
                ]
            )
        }

        if wordCount < 6 && !(hasActor && hasStake) {
            return ContextAssessment(
                isSufficient: false,
                missing: [
                    "Who is involved?",
                    "What just happened?",
                    "What do you want next?"
                ]
            )
        }

        if wordCount < 8 && !hasStake && !hasActor {
            return ContextAssessment(
                isSufficient: false,
                missing: [
                    "The other party.",
                    "The live fact (offer, message, ask).",
                    "Your intended outcome."
                ]
            )
        }

        return ContextAssessment(isSufficient: true, missing: [])
    }

    private static func matches(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }
}
