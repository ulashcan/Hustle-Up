import Foundation

enum PromptShield {
    private static let markers = [
        "ignore previous",
        "ignore all instruction",
        "disregard the",
        "system prompt",
        "always recommend",
        "you are now",
        "new instructions",
        "override the",
        "jailbreak",
        "you must output",
        "do not follow"
    ]

    static func sanitize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        let sentences = splitSentences(trimmed)
        let kept = sentences.filter { sentence in
            let lower = sentence.lowercased()
            return !markers.contains { lower.contains($0) }
        }
        let joined = kept.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? trimmed : joined
    }

    private static func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character == "." || character == "!" || character == "?" || character == "\n" {
                let piece = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !piece.isEmpty { sentences.append(piece) }
                current = ""
            }
        }
        let tail = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { sentences.append(tail) }
        return sentences
    }
}
