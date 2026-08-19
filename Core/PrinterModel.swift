import Foundation

public enum DNPPrinterModel: String, CaseIterable, Identifiable, Sendable {
    case rx1hs = "DNP DS-RX1HS"
    case qw410 = "DNP QW410"

    public var id: String { rawValue }

    public var usbIdentifier: String {
        switch self {
        case .rx1hs: return "1343:0005"
        case .qw410: return "1452:9201"
        }
    }

    public var presets: [DNPPrintPreset] {
        DNPPrintPreset.allCases.filter { $0.model == self }
    }
}

public enum DNPPrintPreset: String, CaseIterable, Identifiable, Sendable {
    case rx1hs4x6 = "4 × 6 in"
    case rx1hs6x8 = "6 × 8 in"
    case qw4104x6 = "4 × 6 in"
    case qw4104_5x8 = "4.5 × 8 in"

    public var id: String { "\(model.rawValue)-\(rawValue)" }

    public var model: DNPPrinterModel {
        switch self {
        case .rx1hs4x6, .rx1hs6x8: return .rx1hs
        case .qw4104x6, .qw4104_5x8: return .qw410
        }
    }

    public var rasterWidth: Int {
        switch self {
        case .rx1hs4x6, .rx1hs6x8: return 1_920
        case .qw4104x6, .qw4104_5x8: return 1_408
        }
    }

    public var rasterHeight: Int {
        switch self {
        case .rx1hs4x6: return 1_240
        case .rx1hs6x8, .qw4104_5x8: return 2_436
        case .qw4104x6: return 1_836
        }
    }

    /// The QW410 requires its full 1,408-dot imaging width even though the
    /// 4-inch image area is 1,266 dots. The remaining 71 dots on each side
    /// are white. RX1HS 4×6 likewise pads 38 dots per side.
    public var horizontalWhiteMargin: Int {
        switch self {
        case .rx1hs4x6: return 38
        case .qw4104x6: return 71
        default: return 0
        }
    }

    public var multicut: Int {
        switch self {
        case .rx1hs4x6: return 2
        case .rx1hs6x8: return 4
        case .qw4104x6: return 48
        case .qw4104_5x8: return 52
        }
    }
}

public enum DNPFinish: String, CaseIterable, Identifiable, Sendable {
    case glossy = "Glossy"
    case matte = "Matte"

    public var id: String { rawValue }

    var commandValue: Int {
        switch self {
        case .glossy: return 0
        case .matte: return 1
        }
    }
}

public struct DNPRasterImage: Sendable {
    public let width: Int
    public let height: Int
    /// 8-bit RGBA, top row first, four bytes per pixel.
    public let rgba: Data

    public init(width: Int, height: Int, rgba: Data) throws {
        guard width > 0, height > 0, rgba.count == width * height * 4 else {
            throw DNPPrintError.invalidRaster
        }
        self.width = width
        self.height = height
        self.rgba = rgba
    }
}

public enum DNPPrintError: LocalizedError, Equatable {
    case invalidRaster
    case rasterDoesNotMatchPreset
    case commandFieldTooLong(String)
    case payloadTooLarge
    case imageRenderingFailed
    case driverNotAvailable
    case printerNotReady(String)
    case transport(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRaster: return "The raster is not valid RGBA data."
        case .rasterDoesNotMatchPreset: return "The raster dimensions do not match the selected print preset."
        case .commandFieldTooLong(let field): return "DNP command field is too long: \(field)."
        case .payloadTooLarge: return "The DNP command payload is too large."
        case .imageRenderingFailed: return "The selected photo could not be rendered."
        case .driverNotAvailable: return "The USB driver is not available. Enable it in iPad Settings and reconnect the printer."
        case .printerNotReady(let reason): return "The printer is not ready: \(reason)"
        case .transport(let detail): return "USB transport failed: \(detail)"
        }
    }
}
