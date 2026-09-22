import Foundation

enum TextCleaner {
    static let maxCharacters = 8000

    static func clean(_ raw: String) -> (text: String, truncated: Bool) {
        var text = raw
        text = text.replacingOccurrences(of: "\u{200B}", with: "")
        text = text.replacingOccurrences(of: "\u{200C}", with: "")
        text = text.replacingOccurrences(of: "\u{200D}", with: "")
        text = text.replacingOccurrences(of: "\u{FEFF}", with: "")
        text = text.replacingOccurrences(of: "\u{00A0}", with: " ")
        text = text.replacingOccurrences(of: "\r\n", with: "\n")
        text = text.replacingOccurrences(of: "\r", with: "\n")

        let lines = text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        text = lines.joined(separator: "\n")

        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
        }
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.count > maxCharacters {
            let index = text.index(text.startIndex, offsetBy: maxCharacters)
            return (String(text[..<index]), true)
        }
        return (text, false)
    }
}
