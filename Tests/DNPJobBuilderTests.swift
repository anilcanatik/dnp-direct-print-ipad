import XCTest
@testable import DNPPrintCore

final class DNPJobBuilderTests: XCTestCase {
    func testRX1HS4x6JobShape() throws {
        let preset = DNPPrintPreset.rx1hs4x6
        let rgba = Data(repeating: 0xFF, count: preset.rasterWidth * preset.rasterHeight * 4)
        let raster = try DNPRasterImage(width: preset.rasterWidth, height: preset.rasterHeight, rgba: rgba)
        let job = try DNPJobBuilder.build(raster: raster, preset: preset)

        let pixelCount = preset.rasterWidth * preset.rasterHeight
        XCTAssertEqual(job.count, 3_552 + pixelCount * 3)
        XCTAssertNotNil(job.range(of: Data("MULTICUT        0000000800000002".utf8)))
        XCTAssertEqual(job.suffix(32), DNPProtocol.startCommand())
    }

    func testQW4104x6JobContainsDeCurlAndCorrectMulticut() throws {
        let preset = DNPPrintPreset.qw4104x6
        let rgba = Data(repeating: 0x80, count: preset.rasterWidth * preset.rasterHeight * 4)
        let raster = try DNPRasterImage(width: preset.rasterWidth, height: preset.rasterHeight, rgba: rgba)
        let job = try DNPJobBuilder.build(raster: raster, preset: preset)

        XCTAssertNotNil(job.range(of: Data("MULTICUT        0000000800000048".utf8)))
        XCTAssertNotNil(job.range(of: Data("DECURL          00000012".utf8)))
    }

    func testRejectsWrongRasterDimensions() throws {
        let raster = try DNPRasterImage(width: 1, height: 1, rgba: Data([0, 0, 0, 255]))
        XCTAssertThrowsError(try DNPJobBuilder.build(raster: raster, preset: .rx1hs4x6))
    }
}

