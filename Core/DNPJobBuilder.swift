import Foundation

public enum DNPJobBuilder {
    private static let bitmapPrefixLength = 1_088

    public static func build(
        raster: DNPRasterImage,
        preset: DNPPrintPreset,
        copies: Int = 1,
        finish: DNPFinish = .glossy,
        deCurlQW410: Bool = true
    ) throws -> Data {
        guard raster.width == preset.rasterWidth, raster.height == preset.rasterHeight else {
            throw DNPPrintError.rasterDoesNotMatchPreset
        }

        let safeCopies = min(max(copies, 1), 999)
        let pixelCount = raster.width * raster.height
        let controlBytes = preset.model == .qw410 ? 204 : 160
        var job = Data()
        job.reserveCapacity(controlBytes + 32 + 3 * (32 + bitmapPrefixLength + pixelCount))

        job.append(try DNPProtocol.command(
            group: "CNTRL",
            name: "OVERCOAT",
            payload: ascii8(finish.commandValue)
        ))
        let quantity = String(format: "%07d\r", safeCopies)
        job.append(try DNPProtocol.command(group: "CNTRL", name: "QTY", payload: Data(quantity.utf8)))
        job.append(try DNPProtocol.command(group: "CNTRL", name: "CUTTER", payload: ascii8(0)))
        job.append(try DNPProtocol.command(group: "IMAGE", name: "MULTICUT", payload: ascii8(preset.multicut)))

        if preset.model == .qw410 {
            let flag = deCurlQW410 ? "01" : "00"
            job.append(try DNPProtocol.command(
                group: "CNTRL",
                name: "DECURL",
                payload: Data("\(flag)00000000\(flag)".utf8)
            ))
        }

        // DNP consumes three 8-bit grayscale BMP-like planes. The public
        // working implementation sends blue as Y, green as M, red as C and
        // reverses each row horizontally.
        for plane in [("YPLANE", 2), ("MPLANE", 1), ("CPLANE", 0)] {
            let bitmap = makePlaneBitmap(raster: raster, componentOffset: plane.1)
            job.append(try DNPProtocol.command(group: "IMAGE", name: plane.0, payload: bitmap))
        }
        job.append(DNPProtocol.startCommand())
        return job
    }

    private static func ascii8(_ value: Int) -> Data {
        Data(String(format: "%08d", value).utf8)
    }

    private static func makePlaneBitmap(raster: DNPRasterImage, componentOffset: Int) -> Data {
        let pixelCount = raster.width * raster.height
        let fileSize = bitmapPrefixLength + pixelCount
        var bitmap = Data()
        bitmap.reserveCapacity(fileSize)

        bitmap.append(contentsOf: [0x42, 0x4D]) // BM
        bitmap.appendLittleEndian(UInt32(fileSize))
        bitmap.append(Data(repeating: 0, count: 4))
        bitmap.appendLittleEndian(UInt32(bitmapPrefixLength))

        bitmap.appendLittleEndian(UInt32(40))
        bitmap.appendLittleEndian(UInt32(raster.width))
        bitmap.appendLittleEndian(UInt32(raster.height))
        bitmap.appendLittleEndian(UInt16(1))
        bitmap.appendLittleEndian(UInt16(8))
        bitmap.append(Data(repeating: 0, count: 8))
        bitmap.appendLittleEndian(UInt32(11_808))
        bitmap.appendLittleEndian(UInt32(11_808))
        bitmap.appendLittleEndian(UInt32(256))
        bitmap.appendLittleEndian(UInt32(0))

        for value in stride(from: 255, through: 0, by: -1) {
            bitmap.append(contentsOf: [UInt8(value), UInt8(value), UInt8(value), 0])
        }
        bitmap.append(Data(repeating: 0, count: 10))
        precondition(bitmap.count == bitmapPrefixLength)

        var plane = Data(repeating: 0, count: pixelCount)
        raster.rgba.withUnsafeBytes { sourceRaw in
            plane.withUnsafeMutableBytes { destinationRaw in
                guard let source = sourceRaw.bindMemory(to: UInt8.self).baseAddress,
                      let destination = destinationRaw.bindMemory(to: UInt8.self).baseAddress else { return }
                for row in 0..<raster.height {
                    let sourceRow = row * raster.width * 4
                    let destinationRow = row * raster.width
                    for column in 0..<raster.width {
                        let reversedColumn = raster.width - column - 1
                        destination[destinationRow + column] = source[sourceRow + reversedColumn * 4 + componentOffset]
                    }
                }
            }
        }
        bitmap.append(plane)
        precondition(bitmap.count == fileSize)
        return bitmap
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}

