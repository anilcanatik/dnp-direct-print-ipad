import Foundation

public enum DNPProtocol {
    public static let headerLength = 32

    /// Creates the 32-byte ESC/P DNP command header followed by its payload.
    public static func command(
        group: String,
        name: String,
        payload: Data = Data()
    ) throws -> Data {
        guard group.utf8.count <= 6 else { throw DNPPrintError.commandFieldTooLong(group) }
        guard name.utf8.count <= 16 else { throw DNPPrintError.commandFieldTooLong(name) }
        guard payload.count <= 99_999_999 else { throw DNPPrintError.payloadTooLarge }

        let groupField = group.padding(toLength: 6, withPad: " ", startingAt: 0)
        let nameField = name.padding(toLength: 16, withPad: " ", startingAt: 0)
        let lengthField = String(format: "%08d", payload.count)

        var data = Data([0x1B, 0x50])
        data.append(contentsOf: groupField.utf8)
        data.append(contentsOf: nameField.utf8)
        data.append(contentsOf: lengthField.utf8)
        precondition(data.count == headerLength)
        data.append(payload)
        return data
    }

    public static func query(group: String = "INFO", name: String) throws -> Data {
        try command(group: group, name: name)
    }

    public static func startCommand() -> Data {
        var data = Data([0x1B, 0x50])
        data.append(contentsOf: "CNTRL".utf8)
        data.append(contentsOf: " START".utf8)
        data.append(Data(repeating: 0x20, count: 19))
        precondition(data.count == headerLength)
        return data
    }

    public static func cleanedASCII(_ response: Data) -> String {
        String(decoding: response, as: UTF8.self)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0\r\n "))
    }

    public static func firstInteger(in response: Data) -> Int? {
        let text = cleanedASCII(response)
        let pieces = text.split(whereSeparator: { !$0.isNumber && $0 != "-" })
        return pieces.lazy.compactMap { Int($0) }.first
    }

    public static func lastInteger(in response: Data) -> Int? {
        let text = cleanedASCII(response)
        let pieces = text.split(whereSeparator: { !$0.isNumber && $0 != "-" })
        return pieces.reversed().lazy.compactMap { Int($0) }.first
    }
}

public struct DNPPrinterProbe: Sendable, Equatable {
    public let statusCode: Int
    public let freeBuffers: Int

    public init(statusCode: Int, freeBuffers: Int) {
        self.statusCode = statusCode
        self.freeBuffers = freeBuffers
    }

    public var isReadyForOneJob: Bool {
        (statusCode == 0 || statusCode == 1) && freeBuffers >= 1
    }

    public var statusText: String {
        switch statusCode {
        case 0: return "Idle"
        case 1: return "Printing"
        case 500: return "Cooling print head"
        case 510: return "Cooling paper motor"
        case 900: return "Waking from standby"
        case 1000: return "Cover open"
        case 1010: return "Scrap box missing"
        case 1100: return "Paper empty"
        case 1200: return "Ribbon empty"
        case 1300: return "Paper jam"
        case 1400: return "Ribbon error"
        case 1500: return "Paper definition error"
        case 1600: return "Print data error"
        default: return "Status \(statusCode)"
        }
    }
}

