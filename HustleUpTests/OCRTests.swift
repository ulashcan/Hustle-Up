import Foundation
import Testing
@testable import HustleUp

struct TextCleanerTests {
    @Test func stripsZeroWidthAndCollapsesSpace() {
        let raw = "Hello\u{200B}   world\n\n\n\nnext"
        let result = TextCleaner.clean(raw)
        #expect(result.text == "Hello world\n\nnext")
        #expect(result.truncated == false)
    }

    @Test func truncatesLongInput() {
        let raw = String(repeating: "a", count: TextCleaner.maxCharacters + 50)
        let result = TextCleaner.clean(raw)
        #expect(result.text.count == TextCleaner.maxCharacters)
        #expect(result.truncated)
    }

    @Test func emptyAfterTrim() {
        let result = TextCleaner.clean("   \n\t  ")
        #expect(result.text.isEmpty)
    }
}

struct OCRAssemblerTests {
    @Test func ordersTopToBottomThenLeftToRight() {
        let lines = [
            OCRLine(text: "bottom", confidence: 0.9, x: 0.1, y: 0.1),
            OCRLine(text: "top-right", confidence: 0.8, x: 0.7, y: 0.9),
            OCRLine(text: "top-left", confidence: 0.7, x: 0.1, y: 0.91)
        ]
        let result = OCRAssembler.assemble(lines: lines)
        #expect(result.cleanedText == "top-left\ntop-right\nbottom")
        #expect(result.observationCount == 3)
    }

    @Test func emptyLinesAreUncertain() {
        let result = OCRAssembler.assemble(lines: [])
        #expect(result.isEmpty)
        #expect(result.isUncertain)
        #expect(result.confidence == 0)
    }
}

struct ImageValidatorTests {
    @Test func rejectsTinyImages() {
        let data = TestImageFactory.png(width: 20, height: 20, checkerboard: true)
        #expect(throws: AppError.imageTooSmall) {
            try ImageValidator().validate(data)
        }
    }

    @Test func rejectsNearEmptyImages() {
        let data = TestImageFactory.png(width: 120, height: 120, checkerboard: false, solid: 12)
        #expect(throws: AppError.imageEmpty) {
            try ImageValidator().validate(data)
        }
    }

    @Test func rejectsGarbageData() {
        #expect(throws: AppError.imageUnsupported) {
            try ImageValidator().validate(Data([0x00, 0x01, 0x02]))
        }
    }

    @Test func acceptsDetailedImages() throws {
        let data = TestImageFactory.png(width: 160, height: 160, checkerboard: true)
        let validated = try ImageValidator().validate(data)
        #expect(validated.width == 160)
        #expect(!validated.pngDataForOCR.isEmpty)
    }

    @Test func downscalesHugeImagesWithoutThrowing() throws {
        let data = TestImageFactory.png(width: 2400, height: 1800, checkerboard: true)
        let validated = try ImageValidator().validate(data)
        #expect(validated.width == 2400)
        #expect(!validated.pngDataForOCR.isEmpty)
    }
}
