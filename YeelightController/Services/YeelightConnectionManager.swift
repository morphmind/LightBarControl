import Foundation
import Network

actor YeelightConnectionManager {
    private var connection: NWConnection?
    private var currentDevice: YeelightDevice?
    private var receiveBuffer = Data()

    private var pendingCommands: [Int: CheckedContinuation<YeelightResponse, Error>] = [:]
    private var notificationHandler: ((YeelightResponse) -> Void)?

    // Rate limiting
    private var requestTimestamps: [Date] = []
    private let maxRequestsPerMinute = 60

    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case failed(Error)
    }

    private(set) var connectionState: ConnectionState = .disconnected

    var isConnected: Bool {
        if case .connected = connectionState {
            return true
        }
        return false
    }

    // MARK: - Connection Management

    func connect(to device: YeelightDevice) async throws {
        // Disconnect existing connection if any
        disconnect()

        currentDevice = device
        connectionState = .connecting

        let host = NWEndpoint.Host(device.ipAddress)
        let port = NWEndpoint.Port(integerLiteral: UInt16(device.port))

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        connection = NWConnection(host: host, port: port, using: parameters)

        return try await withCheckedThrowingContinuation { continuation in
            connection?.stateUpdateHandler = { [weak self] state in
                Task {
                    await self?.handleStateUpdate(state, continuation: continuation)
                }
            }

            connection?.start(queue: DispatchQueue.global(qos: .userInitiated))
        }
    }

    private func handleStateUpdate(_ state: NWConnection.State, continuation: CheckedContinuation<Void, Error>?) {
        switch state {
        case .ready:
            connectionState = .connected
            startReceiving()
            continuation?.resume()
        case .failed(let error):
            connectionState = .failed(error)
            continuation?.resume(throwing: error)
        case .cancelled:
            connectionState = .disconnected
        case .waiting:
            break
        default:
            break
        }
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        currentDevice = nil
        connectionState = .disconnected
        receiveBuffer = Data()

        // Cancel all pending commands
        for (_, continuation) in pendingCommands {
            continuation.resume(throwing: ConnectionError.disconnected)
        }
        pendingCommands.removeAll()
    }

    // MARK: - Send Commands

    func send(_ command: YeelightCommand) async throws -> YeelightResponse {
        guard isConnected, let connection = connection else {
            throw ConnectionError.notConnected
        }

        try await checkRateLimit()

        guard let jsonString = command.toJSONString(),
              let data = jsonString.data(using: .utf8) else {
            throw ConnectionError.invalidCommand
        }


        return try await withCheckedThrowingContinuation { continuation in
            pendingCommands[command.id] = continuation

            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                if let error = error {
                    Task {
                        await self?.removePendingCommand(command.id)
                    }
                    continuation.resume(throwing: error)
                }
            })

            // Timeout after 10 seconds
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                await self?.timeoutCommand(command.id)
            }
        }
    }

    private func removePendingCommand(_ id: Int) {
        pendingCommands.removeValue(forKey: id)
    }

    private func timeoutCommand(_ id: Int) {
        if let continuation = pendingCommands.removeValue(forKey: id) {
            continuation.resume(throwing: ConnectionError.timeout)
        }
    }

    // MARK: - Receive

    private func startReceiving() {
        receiveLoop()
    }

    private func receiveLoop() {
        guard let connection = connection else { return }

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task {
                if let data = data {
                    await self?.handleReceivedData(data)
                }

                if error != nil {
                    return
                }

                if !isComplete {
                    await self?.receiveLoop()
                }
            }
        }
    }

    private func handleReceivedData(_ data: Data) {
        receiveBuffer.append(data)

        // Process complete messages (terminated by \r\n)
        while let range = receiveBuffer.range(of: Data("\r\n".utf8)) {
            let messageData = receiveBuffer.subdata(in: 0..<range.lowerBound)
            receiveBuffer.removeSubrange(0..<range.upperBound)

            if let response = YeelightResponse.parse(messageData) {
                handleResponse(response)
            }
        }
    }

    private func handleResponse(_ response: YeelightResponse) {
        if response.isNotification {
            // Handle notification (state change from external source)
            notificationHandler?(response)
        } else if let id = response.id, let continuation = pendingCommands.removeValue(forKey: id) {
            // Handle command response
            if let error = response.error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: response)
            }
        }
    }

    // MARK: - Rate Limiting

    private func checkRateLimit() async throws {
        // Clean old timestamps
        let now = Date()
        requestTimestamps = requestTimestamps.filter { now.timeIntervalSince($0) < 60 }

        if requestTimestamps.count >= maxRequestsPerMinute {
            let oldestTime = requestTimestamps.first!
            let waitTime = 60 - now.timeIntervalSince(oldestTime)
            if waitTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }

        requestTimestamps.append(now)
    }

    // MARK: - Notification Handler

    func setNotificationHandler(_ handler: @escaping (YeelightResponse) -> Void) {
        notificationHandler = handler
    }
}

// MARK: - Errors

enum ConnectionError: LocalizedError {
    case notConnected
    case disconnected
    case invalidCommand
    case timeout
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to device"
        case .disconnected:
            return "Connection lost"
        case .invalidCommand:
            return "Invalid command"
        case .timeout:
            return "Request timed out"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        }
    }
}
