import Foundation

enum PhraseMatch {
    static func contains(_ haystack: String, _ needle: String) -> Bool {
        if needle.contains(where: \.isWhitespace) {
            return haystack.contains(needle)
        }
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: needle))\\b"
        return haystack.range(of: pattern, options: .regularExpression) != nil
    }

    static func containsAny(_ haystack: String, _ needles: [String]) -> Bool {
        needles.contains { contains(haystack, $0) }
    }

    static func count(_ haystack: String, _ needles: [String]) -> Int {
        needles.filter { contains(haystack, $0) }.count
    }
}
