import Foundation

enum FumbleEngine {
    static func check(message: String, context: FumbleContext) throws -> FumbleCheckResult {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.emptyInput }

        let lower = trimmed.lowercased()
        let wordCount = trimmed.split { $0.isWhitespace || $0.isNewline }.count
        let hedges = ["just", "sorry", "i think", "maybe", "no worries", "whenever", "idk", "i don't know"]
        let hedgeHits = PhraseMatch.count(lower, hedges)

        if revealsPriceAndUrgency(lower) {
            return try result(
                .fumble,
                "You're negotiating against yourself.",
                "You revealed both your price flexibility and urgency before they made another move.",
                "Could you do [your number]?"
            )
        }

        if isSelfNegotiating(lower) || isPrematureConcession(lower) {
            return try result(
                .fumble,
                "You're negotiating against yourself.",
                "The draft gives away leverage before they move. One ask. No apology for existing.",
                tightened(trimmed)
            )
        }

        if isAskingPermission(lower) {
            return try result(
                .fumble,
                "You're asking permission to ask.",
                "A real ask doesn't need a hall pass. Name the number. Drop the 'if that's ok'.",
                tightened(trimmed)
            )
        }

        if isLeakingPrivateFrame(lower) {
            return try result(
                .fumble,
                "You're handing them your leverage.",
                "Off-the-record asides tell them what they can take. Keep the number. Cut the secret.",
                tightened(trimmed)
            )
        }

        if isAggressive(lower, wordCount: wordCount) {
            return try result(
                .fumble,
                "This reads as a threat, not a position.",
                "Heat makes them defensive. Drop the ultimatum. Keep the boundary.",
                "That doesn't work for me. Here's what does: [specific ask]."
            )
        }

        if isDesperate(lower) {
            return try result(
                .fumble,
                "This sounds like you need them more than they need you.",
                "Need is not a strategy. Ask once. Let the silence work.",
                tightened(trimmed)
            )
        }

        if isContradictory(lower) {
            return try result(
                .fumble,
                "You're arguing both sides in one message.",
                "Pick one position. A contradiction invites them to choose the cheaper one.",
                tightened(trimmed)
            )
        }

        if hedgeHits >= 2 || (wordCount > 60 && lower.contains("sorry")) {
            return try result(
                .fumble,
                "You're over-explaining.",
                "Extra context reads as uncertainty. They need the point, not the inner monologue.",
                tightened(trimmed)
            )
        }

        if wordCount > 50 && !hasClearAsk(lower) {
            return try result(
                .tighten,
                "What's the ask?",
                "There's a lot of setup and no sharp request. One sentence that names what you want.",
                tightened(trimmed)
            )
        }

        if context.recommendedMove == .wait {
            return try result(
                .fumble,
                "The move was WAIT.",
                "A polished paragraph is still a send. If the call was wait, don't ship it.",
                nil
            )
        }

        if hedgeHits == 1 || wordCount > 40 {
            return try result(
                .tighten,
                "Almost. Cut the padding.",
                "The extra clauses make you look like you're asking permission to ask.",
                tightened(trimmed)
            )
        }

        if wordCount <= 20 && hedgeHits == 0 {
            return try result(
                .sendIt,
                "Strong and clear.",
                "Short, specific, no groveling. That's the standard.",
                nil
            )
        }

        return try result(
            .sendIt,
            "Strong and clear.",
            "It doesn't leak leverage and it doesn't ramble. Send it.",
            nil
        )
    }

    private static func result(
        _ verdict: FumbleVerdict,
        _ headline: String,
        _ reason: String,
        _ improved: String?
    ) throws -> FumbleCheckResult {
        try FumbleCheckResult(
            verdict: verdict,
            headline: headline,
            reason: reason,
            improvedMessage: improved
        ).validated()
    }

    private static func isSelfNegotiating(_ lower: String) -> Bool {
        matches(lower, [
            "i can go lower",
            "or whatever you think",
            "i'll take whatever",
            "pay me later",
            "you can pay what you want",
            "i'll do it for less"
        ])
    }

    private static func isPrematureConcession(_ lower: String) -> Bool {
        matches(lower, [
            "i can probably do",
            "i could probably do",
            "i might be able to go",
            "i can do $",
            "i can do it for"
        ])
    }

    private static func revealsPriceAndUrgency(_ lower: String) -> Bool {
        isPrematureConcession(lower) && isDesperate(lower)
    }

    private static func isAskingPermission(_ lower: String) -> Bool {
        matches(lower, [
            "if that's ok",
            "if thats ok",
            "if that's okay",
            "if thats okay",
            "if you want",
            "only if you're",
            "no pressure",
            "totally up to you",
            "if that's alright",
            "hope that's okay"
        ])
    }

    private static func isLeakingPrivateFrame(_ lower: String) -> Bool {
        matches(lower, [
            "between us",
            "off the record",
            "don't tell my",
            "dont tell my",
            "don't tell them",
            "dont tell them",
            "just between you and me"
        ])
    }

    private static func isAggressive(_ lower: String, wordCount: Int) -> Bool {
        _ = wordCount
        return matches(lower, [
            "you better",
            "or else",
            "don't waste my time",
            "idiot",
            "stupid",
            "fuck you",
            "do it or i'm out now"
        ])
    }

    private static func isDesperate(_ lower: String) -> Bool {
        matches(lower, [
            "please please",
            "i'll do anything",
            "i really need this",
            "i'm desperate",
            "please i need",
            "i have no other"
        ])
    }

    private static func isContradictory(_ lower: String) -> Bool {
        (lower.contains("i can") && lower.contains("i can't"))
            || (lower.contains("yes") && lower.contains("but no"))
            || (lower.contains("i'm free") && lower.contains("i'm not free"))
            || (lower.contains("i want this") && lower.contains("i don't want this"))
    }

    private static func hasClearAsk(_ lower: String) -> Bool {
        matches(lower, ["i'm asking", "i need", "i want", "can you", "let's do", "i'm at ", "looking for"])
    }

    private static func tightened(_ message: String) -> String {
        let sentences = message
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { sentence in
                let lower = sentence.lowercased()
                return !matches(lower, [
                    "between us",
                    "off the record",
                    "don't tell my",
                    "dont tell my",
                    "don't tell them",
                    "dont tell them",
                    "just between you and me"
                ])
            }
        let kept = Array(sentences.prefix(2))
        if kept.isEmpty {
            return "Here's what I'm asking: [specific ask]."
        }
        var line = kept.joined(separator: ". ") + "."
        for hedge in ["just ", "sorry, ", "sorry ", "i think ", "maybe ", "please please "] {
            line = line.replacingOccurrences(of: hedge, with: "", options: .caseInsensitive)
        }
        return line.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matches(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }
}
