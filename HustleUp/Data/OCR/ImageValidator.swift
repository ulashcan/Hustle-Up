import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

protocol ImageValidating: Sendable {
    func validate(_ data: Data) throws -> ValidatedImage
}

struct ImageValidator: ImageValidating {
    var minDimension: Int
    var maxOCRDimension: Int
    var emptyVarianceThreshold: Double

    init(
        minDimension: Int = 40,
        maxOCRDimension: Int = 2048,
        emptyVarianceThreshold: Double = 12
    ) {
        self.minDimension = minDimension
        self.maxOCRDimension = maxOCRDimension
        self.emptyVarianceThreshold = emptyVarianceThreshold
    }

    func validate(_ data: Data) throws -> ValidatedImage {
        guard data.count > 24 else { throw AppError.imageUnsupported }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw AppError.imageUnsupported
        }

        let width = image.width
        let height = image.height
        guard width >= minDimension, height >= minDimension else {
            throw AppError.imageTooSmall
        }

        if luminanceVariance(of: image) < emptyVarianceThreshold {
            throw AppError.imageEmpty
        }

        let ocrPNG = downscalePNG(image) ?? pngData(from: image) ?? data
        return ValidatedImage(pngDataForOCR: ocrPNG, width: width, height: height)
    }

    private func luminanceVariance(of image: CGImage) -> Double {
        let sampleWidth = min(48, image.width)
        let sampleHeight = min(48, image.height)
        guard sampleWidth > 1, sampleHeight > 1 else { return 0 }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bytesPerRow = sampleWidth
        var pixels = [UInt8](repeating: 0, count: sampleWidth * sampleHeight)
        guard let context = CGContext(
            data: &pixels,
            width: sampleWidth,
            height: sampleHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return 255
        }
        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))

        let values = pixels.map { Double($0) }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        return variance
    }

    private func downscalePNG(_ image: CGImage) -> Data? {
        let longest = max(image.width, image.height)
        guard longest > maxOCRDimension else { return pngData(from: image) }
        let scale = Double(maxOCRDimension) / Double(longest)
        let width = max(1, Int(Double(image.width) * scale))
        let height = max(1, Int(Double(image.height) * scale))
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
            return pngData(from: image)
        }
        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let scaled = context.makeImage() else { return pngData(from: image) }
        return pngData(from: scaled)
    }

    private func pngData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
