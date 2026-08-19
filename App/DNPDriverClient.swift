import DNPPrintCore
import Foundation

final class DNPDriverClient: @unchecked Sendable {
    private let lock = NSLock()
    private var connection: UInt32 = 0

    deinit { disconnect() }

    func connect() throws {
        lock.lock()
        defer { lock.unlock() }
        try connectLocked()
    }

    private func connectLocked() throws {
        if connection != 0 { return }
        connection = dnp_host_open()
        guard connection != 0 else { throw DNPPrintError.driverNotAvailable }
    }

    func disconnect() {
        lock.lock()
        defer { lock.unlock() }
        if connection != 0 {
            dnp_host_close(connection)
            connection = 0
        }
    }

    func query(group: String = "INFO", name: String) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        try connectLocked()
        let request = try DNPProtocol.query(group: group, name: name)
        var response = Data(repeating: 0, count: 4_096)
        var responseLength = response.count
        let result: Int32 = request.withUnsafeBytes { requestBytes in
            response.withUnsafeMutableBytes { responseBytes in
                dnp_host_transact(
                    connection,
                    requestBytes.baseAddress,
                    requestBytes.count,
                    responseBytes.baseAddress,
                    &responseLength
                )
            }
        }
        guard result == 0 else {
            throw DNPPrintError.transport(String(format: "query %@ returned 0x%08X", name, result))
        }
        response.count = responseLength
        return response
    }

    func probe() throws -> DNPPrinterProbe {
        let statusResponse = try query(name: "STATUS")
        let bufferResponse = try query(name: "FREE_PBUFFER")
        guard let status = DNPProtocol.firstInteger(in: statusResponse),
              let freeBuffers = DNPProtocol.lastInteger(in: bufferResponse) else {
            throw DNPPrintError.transport("printer returned an unrecognized status response")
        }
        return DNPPrinterProbe(statusCode: status, freeBuffers: freeBuffers)
    }

    func send(job: Data, progress: @escaping @Sendable (Double) -> Void) throws {
        lock.lock()
        defer { lock.unlock() }
        try connectLocked()
        let chunkSize = 256 * 1_024
        var offset = 0
        while offset < job.count {
            let end = min(offset + chunkSize, job.count)
            let result: Int32 = job.withUnsafeBytes { rawBuffer in
                guard let base = rawBuffer.baseAddress else { return Int32(-1) }
                return dnp_host_write(connection, base.advanced(by: offset), end - offset)
            }
            guard result == 0 else {
                throw DNPPrintError.transport(String(format: "write returned 0x%08X at byte %d", result, offset))
            }
            offset = end
            progress(Double(offset) / Double(job.count))
        }
    }
}
