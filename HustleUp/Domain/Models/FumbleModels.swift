import Foundation

enum FumbleVerdict: String, Codable, Sendable, Equatable, Hashable {
    case fumble
    case sendIt
    case tighten
}

struct FumbleContext: Codable, Sendable, Equatable {
    var situationText: String
    var recommendedMove: MoveVerb?
}

struct FumbleCheckResult: Codable, Sendable, Equatable, Hashable {
    var verdict: FumbleVerdict
    var headline: String
    var reason: String
    var improvedMessage: String?

    func validated() throws -> FumbleCheckResult {
        let headline = headline.trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !headline.isEmpty, !reason.isEmpty else { throw AppError.malformedAIResponse }
        var copy = self
        copy.headline = headline
        copy.reason = reason
        if let improved = improvedMessage?.trimmingCharacters(in: .whitespacesAndNewlines), !improved.isEmpty {
            copy.improvedMessage = improved
        } else {
            copy.improvedMessage = nil
        }
        return copy
    }
}
