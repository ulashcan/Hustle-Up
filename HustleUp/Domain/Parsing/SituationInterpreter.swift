import Foundation

enum SituationInterpreter {
    static func analyze(_ text: String) throws -> SituationAnalysis {
        let cleaned = TextCleaner.clean(text).text
        let shielded = PromptShield.sanitize(cleaned)
        let assessment = ContextGate.assess(shielded)
        if !assessment.isSufficient {
            return try insufficient(shielded, missing: assessment.missing)
        }

        let category = inferCategory(shielded)
        let intent = IntentDetector.detect(shielded)
        let move = inferMove(text: shielded, category: category)
        let confidence = confidenceScore(text: shielded, category: category, move: move)
        let strength = EvidenceStrength.resolve(
            needsMoreContext: false,
            usedFallbackMove: false,
            confidence: confidence
        )

        return try SituationAnalysis(
            situation: situationCopy(text: shielded, category: category),
            userEdge: userEdges(text: shielded, category: category),
            otherSideEdge: otherEdges(text: shielded, category: category),
            risks: risks(text: shielded, category: category),
            knownFacts: knownFacts(text: shielded),
            assumptions: assumptions(text: shielded, category: category),
            unknowns: unknowns(text: shielded, category: category),
            move: move,
            moveReason: moveReason(text: shielded, move: move, category: category),
            suggestedActions: actions(move: move, category: category),
            suggestedResponses: responses(move: move, category: category),
            confidence: confidence,
            category: category,
            usedFallbackMove: false,
            needsMoreContext: false,
            missingContextQuestions: [],
            evidenceStrength: strength,
            intent: intent,
            sharedInterest: EdgeMapBuilder.sharedInterest(category: category),
            moveOptions: MoveSelector.options(primary: move, category: category)
        ).validated()
    }

    private static func insufficient(_ text: String, missing: [String]) throws -> SituationAnalysis {
        _ = text
        return try SituationAnalysis(
            situation: "There isn't enough on the table to call a real move without guessing.",
            userEdge: [],
            otherSideEdge: [],
            risks: ["Acting on a sketch is how people fumble from nowhere."],
            knownFacts: ["We only have a fragment of the situation."],
            assumptions: [],
            unknowns: missing,
            move: .ask,
            moveReason: "A verb now would be theater. Get the missing facts first.",
            suggestedActions: missing,
            suggestedResponses: [],
            confidence: 0.15,
            category: .other,
            usedFallbackMove: false,
            needsMoreContext: true,
            missingContextQuestions: missing,
            evidenceStrength: .unknown
        ).validated()
    }

    static func inferCategory(_ text: String) -> SituationCategory {
        let t = text.lowercased()
        if matches(t, ["raise", "salary", "discount", "invoice", "rate", "rent", "freelance", "quote", "budget", "offer letter", "comp", "lowball"]) {
            return .negotiation
        }
        if matches(t, ["they offered", "got an offer", "the offer is", "offer of"]) {
            return .offer
        }
        if matches(t, ["offer"]) && matches(t, ["boss", "job", "role", "salary", "raise"]) {
            return .offer
        }
        if matches(t, ["argu", "fight", "yelling", "yelled", "conflict", "mad at", "won't talk", "i was wrong", "they lied"]) {
            return .conflict
        }
        if matches(t, ["decline", "say no", "turn it down", "don't want to", "pass on this"]) {
            return .decline
        }
        if matches(t, ["double text", "left me on", "ghost", "should i respond", "said maybe", "not interested", "hang out", "into me"]) {
            return .reply
        }
        if matches(t, ["ask for", "i want to ask", "request", "can i ask"]) {
            return .request
        }
        if matches(t, ["reply", "texted", "message"]) {
            return .reply
        }
        return .other
    }

    static func inferMove(text: String, category: SituationCategory) -> MoveVerb {
        let t = text.lowercased()
        if matches(t, ["threat", "abuse", "unsafe", "harass"]) {
            return .walk
        }
        if matches(t, ["not interested", "leave me alone", "don't contact"]) {
            return .walk
        }
        if matches(t, ["lowball", "insulting offer", "half my rate", "way below"]) {
            return .counter
        }
        if matches(t, ["late night", "drunk", "angry text", "in my feelings", "double text"]) {
            return .wait
        }
        if matches(t, ["busy this week", "maybe", "we'll see", "not sure yet"]) && category == .reply {
            return .wait
        }
        if matches(t, ["i yelled", "i was wrong", "i messed up", "i owe them"]) {
            return .send
        }
        if category == .negotiation || category == .offer {
            if matches(t, ["they offered", "got an offer", "proposed", "the offer", "made an offer"]) {
                return .counter
            }
            return .ask
        }
        if category == .conflict {
            return .wait
        }
        if category == .decline {
            return .send
        }
        if category == .reply {
            if matches(t, ["paragraph", "long message", "wrote this", "already drafted"]) {
                return .wait
            }
            if matches(t, ["let's hang", "they're in", "said yes"]) {
                return .send
            }
            return .ask
        }
        return .ask
    }

    private static func confidenceScore(text: String, category: SituationCategory, move: MoveVerb) -> Double {
        _ = move
        let t = text.lowercased()
        var score = 0.5
        if ContextGate.assess(text).isSufficient { score += 0.08 }
        if category != .other { score += 0.08 }
        if t.contains(where: { $0.isNumber }) { score += 0.1 }
        if matches(t, ["they offered", "they said", "wrote", "asked me"]) { score += 0.08 }
        if matches(t, ["maybe", "idk", "not sure", "vibes"]) { score -= 0.12 }
        return min(max(score, 0.2), 0.86)
    }

    private static func situationCopy(text: String, category: SituationCategory) -> String {
        switch category {
        case .negotiation:
            return "This is a terms conversation. Someone is trying to set the price of your work, time, or money. The next number that gets spoken without an apology usually sticks."
        case .offer:
            return "An offer is already on the table. That means they want something. An offer is an opening bid, not a favor."
        case .conflict:
            if text.lowercased().contains("i was wrong") || text.lowercased().contains("i yelled") {
                return "You already named your part. The risk now is a memoir-length apology that hands them the frame."
            }
            return "Temperature is high. Facts and feelings are tangled. Don't send the version of you that wants to win the minute."
        case .reply:
            return "There's a message in play and the clock is doing work on you. They don't need speed. They need a clean response — or none."
        case .request:
            return "You're about to ask for something. Asking is fine. Asking without a number, a reason, or a boundary is how people get a vague maybe."
        case .decline:
            return "You need a no that doesn't leave a handle. Fuzzy no's become yeses with extra steps."
        case .other:
            let snippet = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = snippet.count > 140 ? String(snippet.prefix(140)) + "…" : snippet
            return "Live situation: \(prefix) Stop narrating. Pick a next move you can actually execute."
        }
    }

    private static func userEdges(text: String, category: SituationCategory) -> [String] {
        let t = text.lowercased()
        var edges: [String] = []
        let alreadyOut = matches(t, [
            "already sent",
            "already replied",
            "already texted",
            "i sent it",
            "i already hit send"
        ])
        let stillHolding = matches(t, [
            "haven't sent",
            "haven't answered",
            "before i send",
            "should i send",
            "draft",
            "already wrote"
        ])
        if stillHolding && !alreadyOut {
            edges.append("LIKELY. It hasn't gone out. You still own timing.")
        }
        if matches(t, ["they offered", "they asked", "reached out", "came to me", "they want me", "client wants"]) {
            edges.append("STRONG SIGNAL. They initiated. That's demand.")
        }
        if matches(t, ["extra team", "already doing", "i've been covering", "performance", "two extra"]) {
            edges.append("LIKELY. You pointed at work already delivered.")
        }
        if category == .reply {
            edges.append("LIKELY. You control whether a reply exists.")
        }
        if edges.isEmpty {
            edges.append("POSSIBLE. You can wait, ask one question, or walk. None of that is confirmed as your plan.")
        } else {
            edges.append("POSSIBLE. You can still slow this down. Not a fact that you will.")
        }
        return edges
    }

    private static func otherEdges(text: String, category: SituationCategory) -> [String] {
        _ = text
        switch category {
        case .negotiation, .offer:
            return [
                "LIKELY. They can say no or stall without explaining the real ceiling.",
                "UNKNOWN. Who else has to approve — not in your text."
            ]
        case .conflict:
            return [
                "POSSIBLE. If they stay louder, they can drag you into their frame.",
                "UNKNOWN. Whether they have an audience you don't see."
            ]
        case .reply:
            return [
                "POSSIBLE. They can read delay as composure or as disinterest. Don't gift a sloppy tell."
            ]
        case .request:
            return [
                "LIKELY. They can say not now without saying never."
            ]
        case .decline:
            return [
                "POSSIBLE. They can make the no feel expensive to keep you talking."
            ]
        case .other:
            return [
                "UNKNOWN. What they actually want next."
            ]
        }
    }

    private static func risks(text: String, category: SituationCategory) -> [String] {
        let t = text.lowercased()
        var items: [String] = []
        if matches(t, ["double text"]) {
            items.append("Another message trains them that your attention is cheap.")
        }
        switch category {
        case .negotiation, .offer:
            items.append("Talking first without a number lets them anchor you.")
            items.append("Over-explaining why you need it sounds like a personal problem.")
        case .conflict:
            items.append("A clever paragraph can still invite another round.")
        case .reply:
            items.append("Speed reads as anxiety.")
        case .request:
            items.append("A soft ask gets a soft no.")
        case .decline:
            items.append("A fuzzy no becomes a yes with extra steps.")
        case .other:
            items.append("Acting before you know what you want.")
        }
        return items
    }

    private static func knownFacts(text: String) -> [String] {
        var facts = ["Known: only what you wrote. Nothing else is confirmed."]
        let t = text.lowercased()
        if matches(t, ["offer"]) {
            facts.append("Known: an offer was mentioned in your words — not a market comparable.")
        }
        if text.contains(where: { $0.isNumber }) {
            facts.append("Known: a number appeared in your text. Treat it as their number or yours, not as 'the market'.")
        }
        return facts
    }

    private static func assumptions(text: String, category: SituationCategory) -> [String] {
        _ = text
        switch category {
        case .negotiation, .offer:
            return [
                "ASSUMPTION. They can move at least a little. Unverified.",
                "ASSUMPTION. You would walk if terms stay bad. Confirm that privately before you counter."
            ]
        default:
            return ["ASSUMPTION. The other side is acting in their interest, not yours."]
        }
    }

    private static func unknowns(text: String, category: SituationCategory) -> [String] {
        _ = text
        switch category {
        case .negotiation, .offer:
            return [
                "UNKNOWN. Their real ceiling — do not invent a market rate.",
                "UNKNOWN. Who else signs off.",
                "UNKNOWN. Their real timeline unless they stated it."
            ]
        default:
            return [
                "UNKNOWN. What they want next.",
                "UNKNOWN. What they do if you wait."
            ]
        }
    }

    private static func moveReason(text: String, move: MoveVerb, category: SituationCategory) -> String {
        let t = text.lowercased()
        switch move {
        case .counter:
            return "They've shown a number or a frame. Counter once with a clean alternative — not a speech."
        case .wait:
            if t.contains("double text") {
                return "Don't send another message yet. The last one is still working, even if it doesn't feel like it."
            }
            if category == .conflict || category == .reply {
                return "This is hot. Anything you send now is evidence. Draft. Don't deliver."
            }
            return "You don't have enough, or the timing is sloppy. Waiting is refusing a bad tempo."
        case .ask:
            if category == .negotiation || category == .offer {
                return "Ask one precise question: range, decision-maker, or timeline. Don't stack five."
            }
            return "The next fact changes the move. Get it. Don't perform certainty you don't have."
        case .send:
            if t.contains("i was wrong") || t.contains("i yelled") {
                return "One short ownership line. Then stop. A paragraph apology is a second fight."
            }
            return "The position is already clear. More drafting will add apology. Send the short version."
        case .walk:
            return "Staying trains them that this is acceptable. Close the loop in one line. Don't debate the goodbye."
        }
    }

    private static func actions(move: MoveVerb, category: SituationCategory) -> [String] {
        _ = category
        switch move {
        case .counter:
            return [
                "Counter once: a number or a condition. Then stop.",
                "Don't explain your rent or their budget for them."
            ]
        case .wait:
            return [
                "Don't send another message yet.",
                "If you must type, do it in Fumble Check — not the live thread."
            ]
        case .ask:
            return [
                "Ask one direct question that unlocks the real constraint.",
                "If this is money, don't volunteer a number first unless they already forced the bid."
            ]
        case .send:
            return [
                "Send the short version.",
                "No follow-up 'just checking in' today."
            ]
        case .walk:
            return [
                "Close it in one line.",
                "Don't debate the goodbye."
            ]
        }
    }

    private static func responses(move: MoveVerb, category: SituationCategory) -> [String] {
        switch (move, category) {
        case (.counter, .negotiation), (.counter, .offer):
            return [
                "Thanks for this. I'm looking for [X]. If we can land there, I'm in.",
                "I can do [X] on [terms]. Below that doesn't work for me."
            ]
        case (.ask, .negotiation), (.ask, .offer):
            return [
                "Before I answer: what's the range you had in mind?",
                "Who else needs to sign off, and what's the timeline on your side?"
            ]
        case (.wait, _):
            return ["(Don't send.) If you must: I need to think about this — I'll come back tomorrow."]
        case (.send, .decline):
            return [
                "Going to pass on this. Thanks for thinking of me.",
                "I can't take this on. Hope it goes well."
            ]
        case (.send, _):
            return [
                "That was on me. I'm sorry. That's the line.",
                "Works on my side. Send the next step."
            ]
        case (.walk, _):
            return [
                "I'm going to stop here. Take care.",
                "This isn't a fit. I'll leave it there."
            ]
        default:
            return ["Can you say what you need from me in one sentence?"]
        }
    }

    private static func matches(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }
}
