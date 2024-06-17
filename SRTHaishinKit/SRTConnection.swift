import Foundation
import libsrt

/// The SRTConnection class create a two-way SRT connection.
public final class SRTConnection: NSObject {
    /// The error comain codes.
    public enum Error: Swift.Error {
        case notSupportedUri(_ uri: URL?)
        case failedToConnect(_ message: String, reson: Int32)
    }

    /// The SRT Library version
    public static let version: String = SRT_VERSION_STRING
    /// The URI passed to the SRTConnection.connect() method.
    public private(set) var uri: URL?
    /// This instance connect to server(true) or not(false)
    @objc public private(set) dynamic var connected = false

    var socket: SRTSocket<SRTConnection>? {
        didSet {
            socket?.delegate = self
        }
    }
    var streams: [SRTStream] = []
    var clients: [SRTSocket<SRTConnection>] = []

    /// The SRT's performance data.
    public var performanceData: SRTPerformanceData? {
        guard let socket else {
            return nil
        }
        _ = socket.bstats()
        return SRTPerformanceData(mon: socket.perf)
    }

    /// Creates an object.
    override public init() {
        super.init()
        srt_startup()
    }

    deinit {
        streams.removeAll()
        srt_cleanup()
    }

    /// Open a two-way connection to an application on SRT Server.
    public func open(_ uri: URL?, mode: SRTMode = .caller) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard let uri = uri, let scheme = uri.scheme, let host = uri.host, let port = uri.port, scheme == "srt" else {
                continuation.resume(throwing: Error.notSupportedUri(uri))
                return
            }
            do {
                let options = SRTSocketOption.from(uri: uri)
                let addr = sockaddr_in(mode.host(host), port: UInt16(port))
                socket = .init()
                try socket?.open(addr, mode: mode, options: options)
                self.uri = uri
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Closes the connection from the server.
    public func close() async {
        for client in clients {
            client.close()
        }
        for stream in streams {
            stream.close()
        }
        socket?.close()
        clients.removeAll()
    }

    private func sockaddr_in(_ host: String, port: UInt16) -> sockaddr_in {
        var addr: sockaddr_in = .init()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = CFSwapInt16BigToHost(UInt16(port))
        if inet_pton(AF_INET, host, &addr.sin_addr) == 1 {
            return addr
        }
        guard let hostent = gethostbyname(host), hostent.pointee.h_addrtype == AF_INET else {
            return addr
        }
        addr.sin_addr = UnsafeRawPointer(hostent.pointee.h_addr_list[0]!).assumingMemoryBound(to: in_addr.self).pointee
        return addr
    }
}

extension SRTConnection: SRTSocketDelegate {
    // MARK: SRTSocketDelegate
    func socket(_ socket: SRTSocket<SRTConnection>, status: SRT_SOCKSTATUS) {
        if let socketStatus = SocketStatus(srtStatus: status) {
            NotificationCenter.default.post(
                name: SRTNotificationNames.connectionStatusNotification,
                object: self,
                userInfo: [SRTNotificationProperties.status: socketStatus]
            )
        }
        connected = socket.status == SRTS_CONNECTED
    }

    func socket(_ socket: SRTSocket<SRTConnection>, incomingDataAvailabled data: Data, bytes: Int32) {
        streams.first?.doInput(data.subdata(in: 0..<Data.Index(bytes)))
    }

    func socket(_ socket: SRTSocket<SRTConnection>, didAcceptSocket client: SRTSocket<SRTConnection>) {
        clients.append(client)
    }
}
