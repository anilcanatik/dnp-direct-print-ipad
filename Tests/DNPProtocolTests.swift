import XCTest
@testable import DNPPrintCore

final class DNPProtocolTests: XCTestCase {
    func testCommandHeaderIsExactly32Bytes() throws {
        let command = try DNPProtocol.command(
            group: "INFO",
            name: "STATUS",
            payload: Data("12345678".utf8)
        )
        XCTAssertEqual(command.count, 40)
        XCTAssertEqual(Array(command.prefix(2)), [0x1B, 0x50])
        XCTAssertEqual(String(decoding: command[24..<32], as: UTF8.self), "00000008")
    }

    func testStartCommandIsExactly32Bytes() {
        let command = DNPProtocol.startCommand()
        XCTAssertEqual(command.count, 32)
        XCTAssertEqual(String(decoding: command.prefix(13), as: UTF8.self), "\u{1B}PCNTRL START")
    }

    func testProbeParsing() {
        XCTAssertEqual(DNPProtocol.firstInteger(in: Data("00000000\r".utf8)), 0)
        XCTAssertEqual(DNPProtocol.lastInteger(in: Data("BUF02\r".utf8)), 2)
    }
}

