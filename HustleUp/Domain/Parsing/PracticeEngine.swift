import Foundation

enum PracticeEngine {
    static func reply(session: PracticeSession, userMessage: String) throws -> PracticeTurnResult {
        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.emptyInput }
        let replies = script(for: session)
        let turnIndex = min(session.userTurnCount, replies.count - 1)
        let reply = adaptedReply(scripted: replies[turnIndex], userMessage: trimmed)
        return PracticeTurnResult(
            otherPartyReply: reply,
            shouldOfferToFinish: session.userTurnCount >= 1
        )
    }

    static func score(_ session: PracticeSession) throws -> PracticeScorecard {
        let userTurns = session.turns.filter { $0.role == .user }.map(\.text)
        guard !userTurns.isEmpty else { throw AppError.emptyInput }
        let joined = userTurns.joined(separator: " ").lowercased()
        let words = joined.split { $0.isWhitespace }.count
        let hedges = PhraseMatch.count(joined, ["sorry", "just", "maybe", "i think"])
        let hasAsk = joined.contains("asking") || joined.contains("i need") || joined.contains("i want") || joined.contains("%") || joined.contains("k")
        let leaked = matches(joined, [
            "i can go lower",
            "whatever you think",
            "i really need",
            "i can probably",
            "i'll do anything"
        ])

        let confidence = clamp(8 - hedges * 2 + (hasAsk ? 1 : 0))
        let clarity = clamp(words < 8 ? 4 : words > 120 ? 4 : 8)
        let persuasion = clamp((joined.contains("because") || joined.contains("when") || hasAsk) ? 8 : 6)
        let positioning = clamp(leaked ? 3 : (hasAsk ? 7 : 5))
        let leverage = clamp(leaked ? 3 : (hasAsk ? 7 : 5))
        let timing = clamp(matches(joined, ["right now", "immediately", "today or i"]) ? 4 : 7)
        let risk = clamp(matches(joined, ["or else", "you better"]) ? 2 : 7)

        let mistake: String
        if leaked {
            mistake = "You conceded leverage — need or a cheaper number — before they moved."
        } else if hedges > 0 {
            mistake = "You softened the ask until it sounded optional."
        } else if !hasAsk {
            mistake = "You talked around it. There was no sharp ask."
        } else {
            mistake = "You answered their frame instead of resetting it."
        }

        let worked: String
        if hasAsk && !leaked {
            worked = "You named the ask without volunteering extra need."
        } else if hasAsk {
            worked = "You named an ask."
        } else {
            worked = "You stayed in the conversation."
        }

        let improvement = leaked
            ? "Ask once. Do not name your floor. Do not name your need."
            : "Lead with the ask, then one proof point. Stop talking."

        return try PracticeScorecard(
            confidence: confidence,
            clarity: clarity,
            persuasion: persuasion,
            strategicPositioning: positioning,
            leveragePreservation: leverage,
            timing: timing,
            riskManagement: risk,
            strongestMistake: mistake,
            suggestedImprovement: improvement,
            whatYouDid: "You made \(userTurns.count) move\(userTurns.count == 1 ? "" : "s"). \(hasAsk ? "You named an ask." : "You never named the ask.")",
            whatWorked: worked,
            whatHurt: mistake,
            nextMove: improvement
        ).validated()
    }

    private static func adaptedReply(scripted: String, userMessage: String) -> String {
        let lower = userMessage.lowercased()
        if matches(lower, ["or else", "you better", "don't waste my time"]) {
            return "If that's the tone, I can end this now."
        }
        if matches(lower, ["i really need", "i can probably", "i can go lower", "whatever you think"]) {
            return "That sounds like you have room. What's the number you actually need?"
        }
        if PhraseMatch.containsAny(lower, ["sorry", "just", "i think", "maybe"]) {
            return "That sounds optional. What's the actual ask?"
        }
        return scripted
    }

    private static func script(for session: PracticeSession) -> [String] {
        let t = (session.otherPartyRole + " " + session.scenario).lowercased()
        if matches(t, ["landlord", "lease"]) {
            return [
                "Market's up on this unit. That's the lease.",
                "I can list it tomorrow.",
                "If I said maybe on a smaller bump — what's your number?",
                "I need a yes on the new rent by Friday."
            ]
        }
        if matches(t, ["recruiter"]) {
            return [
                "…",
                "The hiring manager wants a number before we share the band.",
                "Other candidates already named a range.",
                "I need something I can take back today."
            ]
        }
        if matches(t, ["customer support", "refund", "charge is final"]) {
            return [
                "The charge is final on our side.",
                "I don't have a supervisor on this chat.",
                "If I made an exception, what are you actually asking for?",
                "I can close the ticket or escalate. Pick one."
            ]
        }
        if t.contains("raise") || t.contains("salary") || t.contains("boss") {
            return [
                "I'm listening. Why now?",
                "That's not how I see the budget this quarter.",
                "If I said maybe — what number are you actually asking for?",
                "I need one sentence I can take upstairs."
            ]
        }
        if t.contains("discount") || t.contains("client") || t.contains("rate") || t.contains("freelance") {
            return [
                "We have other quotes in play.",
                "Can you do it for less? That's what I'm hearing from my side.",
                "What's the real number if I sign this week?",
                "I need a yes/no I can take to the buyer."
            ]
        }
        if t.contains("argu") || t.contains("conflict") || t.contains("fight") {
            return [
                "So this is my fault?",
                "You're not hearing me.",
                "Fine. What do you actually want from me?",
                "I don't have all day. One sentence."
            ]
        }
        if t.contains("reply") || t.contains("text") || t.contains("date") || t.contains("hang") {
            return [
                "Hey — been busy.",
                "I don't know yet.",
                "Why the extra messages?",
                "What do you want from this?"
            ]
        }
        return [
            "I'm listening. Why now?",
            "That's not how I see this from my side.",
            "If I said maybe — what are you actually asking for?",
            "I need something I can take to the other side. One sentence."
        ]
    }

    private static func matches(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, 1), 10)
    }
}
