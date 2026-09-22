import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import HustleUp

enum TestImageFactory {
    static func png(width: Int, height: Int, checkerboard: Bool, solid: UInt8 = 20) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Data()
        }
        if checkerboard {
            let size = 8
            for y in stride(from: 0, to: height, by: size) {
                for x in stride(from: 0, to: width, by: size) {
                    let on = ((x / size) + (y / size)) % 2 == 0
                    context.setFillColor(on ? CGColor(gray: 0.1, alpha: 1) : CGColor(gray: 0.9, alpha: 1))
                    context.fill(CGRect(x: x, y: y, width: size, height: size))
                }
            }
        } else {
            context.setFillColor(CGColor(gray: CGFloat(solid) / 255, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        guard let image = context.makeImage() else { return Data() }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return Data()
        }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        return data as Data
    }
}

@MainActor
enum TestAppFactory {
    static func model(
        ai: any AIServicing = MockAIService(delay: .zero),
        ocr: any OCRServicing = StubOCRService(
            result: OCRResult(rawText: "hello", cleanedText: "hello", confidence: 0.9, observationCount: 1, wasTruncated: false),
            error: nil
        ),
        pro: Bool = false,
        analytics: InMemoryAnalytics = InMemoryAnalytics(),
        arguments: [String] = []
    ) -> (AppModel, InMemoryAnalytics) {
        let defaults = UserDefaults(suiteName: "hu.test.\(UUID().uuidString)") ?? .standard
        let entitlements = EntitlementStore(defaults: defaults)
        if pro { entitlements.setProPreview(true) }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("hu-\(UUID().uuidString).json")
        let environment = AppEnvironment(
            ai: ai,
            ocr: ocr,
            validator: ImageValidator(),
            store: FileAnalysisStore(fileURL: url),
            entitlements: entitlements,
            analytics: analytics,
            skipOnboardingDefault: true
        )
        return (AppModel(environment: environment, arguments: arguments), analytics)
    }
}

final class FlakyAIService: AIServicing, @unchecked Sendable {
    private let lock = NSLock()
    private var failuresRemaining: Int

    init(failuresRemaining: Int) {
        self.failuresRemaining = failuresRemaining
    }

    func setFailures(_ count: Int) {
        lock.lock()
        failuresRemaining = count
        lock.unlock()
    }

    func analyze(input: AnalysisRequest) async throws -> SituationAnalysis {
        try consumeFailure()
        return try SituationInterpreter.analyze(input.text)
    }

    func checkFumble(message: String, context: FumbleContext) async throws -> FumbleCheckResult {
        try consumeFailure()
        return try FumbleEngine.check(message: message, context: context)
    }

    func practiceTurn(session: PracticeSession, userMessage: String) async throws -> PracticeTurnResult {
        try consumeFailure()
        return try PracticeEngine.reply(session: session, userMessage: userMessage)
    }

    func scorePractice(session: PracticeSession) async throws -> PracticeScorecard {
        try consumeFailure()
        return try PracticeEngine.score(session)
    }

    private func consumeFailure() throws {
        lock.lock()
        let shouldFail = failuresRemaining > 0
        if shouldFail { failuresRemaining -= 1 }
        lock.unlock()
        if shouldFail { throw AppError.timedOut }
    }
}

struct SlowOCRService: OCRServicing {
    var delay: Duration = .milliseconds(400)

    func extractText(from imageData: Data) async throws -> OCRResult {
        _ = imageData
        try await Task.sleep(for: delay)
        return OCRResult(
            rawText: "hello",
            cleanedText: "hello",
            confidence: 0.9,
            observationCount: 1,
            wasTruncated: false
        )
    }
}
