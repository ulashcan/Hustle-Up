import Foundation

enum MoveSelector {
    static func options(primary: MoveVerb, category: SituationCategory) -> [MoveOption] {
        let recommended = make(primary, recommended: true, category: category)
        let alts = alternatives(for: primary, category: category).map {
            make($0, recommended: false, category: category)
        }
        return [recommended] + alts
    }

    static func alternatives(for primary: MoveVerb, category: SituationCategory) -> [MoveVerb] {
        switch primary {
        case .counter:
            return [.ask, .wait]
        case .wait:
            return [.ask, .send]
        case .ask:
            return [.wait, (category == .negotiation || category == .offer) ? .counter : .send]
        case .send:
            return [.wait, .ask]
        case .walk:
            return [.wait, .ask]
        }
    }

    private static func make(_ move: MoveVerb, recommended: Bool, category: SituationCategory) -> MoveOption {
        _ = category
        switch move {
        case .counter:
            return MoveOption(
                move: .counter,
                purpose: "Reset the number without a speech.",
                risk: "If you jump too far, you give away room.",
                upside: "You stop absorbing their frame.",
                execution: "Name one number or condition. Then stop.",
                isRecommended: recommended
            )
        case .wait:
            return MoveOption(
                move: .wait,
                purpose: "Refuse a bad tempo.",
                risk: "Silence can be read as disinterest.",
                upside: "You keep optionality.",
                execution: "Draft. Don't deliver.",
                isRecommended: recommended
            )
        case .ask:
            return MoveOption(
                move: .ask,
                purpose: "Get the missing fact before you give one away.",
                risk: "A vague question invites a vague answer.",
                upside: "The next fact can change the verb.",
                execution: "One precise question. Not five.",
                isRecommended: recommended
            )
        case .send:
            return MoveOption(
                move: .send,
                purpose: "Close the loop while the position is still clean.",
                risk: "A long send becomes a second fight.",
                upside: "You stop rehearsing.",
                execution: "Send the short version. No follow-up today.",
                isRecommended: recommended
            )
        case .walk:
            return MoveOption(
                move: .walk,
                purpose: "Stop training them that this is acceptable.",
                risk: "A debate about the goodbye keeps you in it.",
                upside: "You exit with one line.",
                execution: "Close it. Don't argue the door.",
                isRecommended: recommended
            )
        }
    }
}
