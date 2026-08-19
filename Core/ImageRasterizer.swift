import Foundation
import UIKit

public enum DNPImageRasterizer {
    public static func rasterize(_ image: UIImage, for preset: DNPPrintPreset) throws -> DNPRasterImage {
        let targetSize = CGSize(width: preset.rasterWidth, height: preset.rasterHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        let rendered = UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))

            let margin = CGFloat(preset.horizontalWhiteMargin)
            let contentRect = CGRect(
                x: margin,
                y: 0,
                width: targetSize.width - (margin * 2),
                height: targetSize.height
            )
            let sourceSize = image.size
            let scale = max(contentRect.width / sourceSize.width, contentRect.height / sourceSize.height)
            let drawSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
            let drawRect = CGRect(
                x: contentRect.midX - drawSize.width / 2,
                y: contentRect.midY - drawSize.height / 2,
                width: drawSize.width,
                height: drawSize.height
            )
            context.cgContext.saveGState()
            context.cgContext.clip(to: contentRect)
            image.draw(in: drawRect)
            context.cgContext.restoreGState()
        }

        guard let cgImage = rendered.cgImage else { throw DNPPrintError.imageRenderingFailed }
        var bytes = Data(repeating: 0xFF, count: preset.rasterWidth * preset.rasterHeight * 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let renderedSuccessfully = bytes.withUnsafeMutableBytes { rawBuffer -> Bool in
            guard let baseAddress = rawBuffer.baseAddress,
                  let context = CGContext(
                    data: baseAddress,
                    width: preset.rasterWidth,
                    height: preset.rasterHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: preset.rasterWidth * 4,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
                  ) else { return false }
            context.interpolationQuality = .high
            context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
            return true
        }
        guard renderedSuccessfully else { throw DNPPrintError.imageRenderingFailed }
        return try DNPRasterImage(width: preset.rasterWidth, height: preset.rasterHeight, rgba: bytes)
    }
}

