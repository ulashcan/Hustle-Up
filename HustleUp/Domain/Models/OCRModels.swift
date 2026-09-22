import Foundation
import CoreGraphics

struct OCRLine: Sendable, Equatable {
    var text: String
    var confidence: Double
    var x: CGFloat
    var y: CGFloat
}

struct OCRResult: Sendable, Equatable {
    var rawText: String
    var cleanedText: String
    var confidence: Double
    var observationCount: Int
    var wasTruncated: Bool

    var isUncertain: Bool {
        observationCount == 0
            || cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || confidence < 0.55
    }

    var isEmpty: Bool {
        cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ValidatedImage: Sendable {
    let pngDataForOCR: Data
    let width: Int
    let height: Int
}
