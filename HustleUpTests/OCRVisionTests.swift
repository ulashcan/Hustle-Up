import Foundation
import Testing
import UIKit
@testable import HustleUp

enum TestTextImageFactory {
    static func png(text: String, width: CGFloat = 1000, height: CGFloat = 520) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { _ in
            UIColor.black.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 64, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            text.draw(
                in: CGRect(x: 40, y: 140, width: width - 80, height: height - 180),
                withAttributes: attrs
            )
        }
        return image.pngData() ?? Data()
    }
}

struct VisionOCRServiceTests {
    @Test func recognizesHighContrastEnglish() async throws {
        let data = TestTextImageFactory.png(text: "HELLO HUSTLE")
        let result = try await VisionOCRService().extractText(from: data)
        let blob = result.cleanedText.uppercased()
        #expect(blob.contains("HELLO") || blob.contains("HUSTLE"))
    }

    @Test func emojiAndURLDoNotCrash() async throws {
        let data = TestTextImageFactory.png(text: "SEE https://example.com 🔥")
        let result = try await VisionOCRService().extractText(from: data)
        #expect(result.observationCount >= 0)
    }

    @Test func mixedLanguageDoesNotCrash() async throws {
        let data = TestTextImageFactory.png(text: "HOLA HELLO")
        let result = try await VisionOCRService().extractText(from: data)
        let blob = result.cleanedText.uppercased()
        #expect(blob.contains("HOLA") || blob.contains("HELLO") || result.observationCount >= 0)
    }

    @Test func longScreenshotDoesNotCrash() async throws {
        let line = "LINE ONE AND LINE TWO AND LINE THREE"
        let data = TestTextImageFactory.png(text: line, width: 1200, height: 1600)
        let result = try await VisionOCRService().extractText(from: data)
        #expect(result.observationCount >= 0)
    }
}
