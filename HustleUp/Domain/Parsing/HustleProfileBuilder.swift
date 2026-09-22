import Foundation

struct ProfileObservation: Sendable, Equatable, Identifiable, Hashable {
    var id: String
    var title: String
    var detail: String
    var count: Int
    var samples: [String]
}

enum HustleProfileBuilder {
    static let minimumRepeats = 2

    static func observations(from items: [StoredAnalysis]) -> [ProfileObservation] {
        var buckets: [String: (move: MoveVerb, outcome: MoveOutcome, count: Int)] = [:]
        for item in items {
            guard !item.analysis.needsMoreContext, let outcome = item.outcome else { continue }
            let key = "\(item.analysis.move.rawValue)|\(outcome.result.rawValue)"
            let existing = buckets[key]
            buckets[key] = (
                move: item.analysis.move,
                outcome: outcome.result,
                count: (existing?.count ?? 0) + 1
            )
        }

        return buckets.values
            .filter { $0.count >= minimumRepeats }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.move.rawValue < rhs.move.rawValue
            }
            .map(makeObservation)
    }

    private static func makeObservation(_ bucket: (move: MoveVerb, outcome: MoveOutcome, count: Int)) -> ProfileObservation {
        let sample = "\(bucket.move.rawValue) → \(bucket.outcome.displayName)"
        return ProfileObservation(
            id: "\(bucket.move.rawValue)-\(bucket.outcome.rawValue)",
            title: title(move: bucket.move, outcome: bucket.outcome),
            detail: "Observed \(bucket.count) times: \(sample). That's a count, not a diagnosis.",
            count: bucket.count,
            samples: Array(repeating: sample, count: bucket.count)
        )
    }

    private static func title(move: MoveVerb, outcome: MoveOutcome) -> String {
        switch (move, outcome) {
        case (.counter, .no):
            return "COUNTER didn't land"
        case (.counter, .yes):
            return "COUNTER has been landing"
        case (.wait, .yes):
            return "WAIT paid off"
        case (.wait, .no):
            return "WAIT didn't get the result"
        case (.ask, .yes):
            return "ASK unlocked the next fact"
        case (.ask, .no):
            return "ASK didn't move it"
        case (.send, .yes):
            return "SEND closed the loop"
        case (.send, .no):
            return "SEND didn't land"
        case (.walk, .yes):
            return "WALK held"
        case (.walk, .no):
            return "WALK didn't feel like a win"
        case (_, .partly):
            return "\(move.rawValue) was only partial"
        case (_, .notSure):
            return "\(move.rawValue) is still too early to call"
        }
    }
}
