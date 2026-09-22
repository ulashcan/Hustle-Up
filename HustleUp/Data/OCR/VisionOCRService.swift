import CoreGraphics
import Foundation
import ImageIO
import Vision

protocol OCRServicing: Sendable {
    func extractText(from imageData: Data) async throws -> OCRResult
}

enum OCRAssembler {
    static func assemble(lines: [OCRLine]) -> OCRResult {
        let sorted = lines.sorted { lhs, rhs in
            if abs(lhs.y - rhs.y) > 0.02 {
                return lhs.y > rhs.y
            }
            return lhs.x < rhs.x
        }
        let raw = sorted
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        let cleaned = TextCleaner.clean(raw)
        let confidence: Double
        if sorted.isEmpty {
            confidence = 0
        } else {
            confidence = sorted.map(\.confidence).reduce(0, +) / Double(sorted.count)
        }
        return OCRResult(
            rawText: raw,
            cleanedText: cleaned.text,
            confidence: confidence,
            observationCount: sorted.count,
            wasTruncated: cleaned.truncated
        )
    }
}

struct VisionOCRService: OCRServicing {
    func extractText(from imageData: Data) async throws -> OCRResult {
        try await Task.detached(priority: .userInitiated) {
            try Self.recognize(imageData)
        }.value
    }

    private static func recognize(_ data: Data) throws -> OCRResult {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw AppError.ocrFailed
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw AppError.ocrFailed
        }

        let observations = request.results ?? []
        let lines: [OCRLine] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            return OCRLine(
                text: candidate.string,
                confidence: Double(candidate.confidence),
                x: box.origin.x,
                y: box.origin.y
            )
        }
        return OCRAssembler.assemble(lines: lines)
    }
}

struct StubOCRService: OCRServicing {
    var result: OCRResult
    var error: AppError?

    func extractText(from imageData: Data) async throws -> OCRResult {
        _ = imageData
        if let error { throw error }
        return result
    }
}
