import Foundation
import Darwin

actor DeviceDiscoveryService {
    private let multicastAddress = "239.255.255.250"
    private let multicastPort: UInt16 = 1982
    private let searchMessage = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1982\r\nMAN: \"ssdp:discover\"\r\nST: wifi_bulb\r\n\r\n"

    private var discoveredDevices: [String: YeelightDevice] = [:]

    // MARK: - Discovery with BSD Socket

    func discoverDevices(timeout: TimeInterval = 5.0) async throws -> [YeelightDevice] {
        discoveredDevices.removeAll()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let devices = try self.performBSDSocketDiscovery(timeout: timeout)
                    continuation.resume(returning: devices)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private nonisolated func performBSDSocketDiscovery(timeout: TimeInterval) throws -> [YeelightDevice] {
        var foundDevices: [String: YeelightDevice] = [:]
        let lock = NSLock()

        // Create UDP socket
        let sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard sock >= 0 else {
            throw DiscoveryError.socketCreationFailed
        }
        defer { close(sock) }

        // Enable address reuse
        var reuse: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, &reuse, socklen_t(MemoryLayout<Int32>.size))

        // Bind to any address on the multicast port
        var bindAddr = sockaddr_in()
        bindAddr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        bindAddr.sin_family = sa_family_t(AF_INET)
        bindAddr.sin_port = multicastPort.bigEndian
        bindAddr.sin_addr.s_addr = INADDR_ANY.bigEndian

        let bindResult = withUnsafePointer(to: &bindAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult >= 0 else {
            throw DiscoveryError.bindFailed
        }

        // Join multicast group
        var mreq = ip_mreq()
        mreq.imr_multiaddr.s_addr = inet_addr(multicastAddress)
        mreq.imr_interface.s_addr = INADDR_ANY.bigEndian

        let joinResult = setsockopt(sock, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, socklen_t(MemoryLayout<ip_mreq>.size))
        guard joinResult >= 0 else {
            throw DiscoveryError.multicastJoinFailed
        }

        // Set TTL for multicast
        var ttl: UInt8 = 2
        setsockopt(sock, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, socklen_t(MemoryLayout<UInt8>.size))

        // Set receive timeout
        var tv = timeval()
        tv.tv_sec = Int(timeout)
        tv.tv_usec = Int32((timeout.truncatingRemainder(dividingBy: 1)) * 1_000_000)
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        // Send M-SEARCH message
        var destAddr = sockaddr_in()
        destAddr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        destAddr.sin_family = sa_family_t(AF_INET)
        destAddr.sin_port = multicastPort.bigEndian
        destAddr.sin_addr.s_addr = inet_addr(multicastAddress)

        let messageData = searchMessage.data(using: .utf8)!
        let sendResult = messageData.withUnsafeBytes { buffer in
            withUnsafePointer(to: &destAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { destPtr in
                    sendto(sock, buffer.baseAddress, buffer.count, 0, destPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }

        guard sendResult >= 0 else {
            throw DiscoveryError.sendFailed
        }


        // Receive responses
        var buffer = [UInt8](repeating: 0, count: 2048)
        var sourceAddr = sockaddr_in()
        var sourceLen = socklen_t(MemoryLayout<sockaddr_in>.size)

        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let recvLen = withUnsafeMutablePointer(to: &sourceAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { srcPtr in
                    recvfrom(sock, &buffer, buffer.count, 0, srcPtr, &sourceLen)
                }
            }

            if recvLen > 0 {
                let responseData = Data(bytes: buffer, count: recvLen)
                if let response = String(data: responseData, encoding: .utf8) {
                    if let device = YeelightDevice.fromDiscoveryResponse(response) {
                        lock.lock()
                        foundDevices[device.id] = device
                        lock.unlock()
                    }
                }
            } else if recvLen < 0 {
                let err = errno
                if err == EAGAIN || err == EWOULDBLOCK {
                    // Timeout, continue checking if total timeout exceeded
                    continue
                }
                break
            }
        }

        // Leave multicast group
        setsockopt(sock, IPPROTO_IP, IP_DROP_MEMBERSHIP, &mreq, socklen_t(MemoryLayout<ip_mreq>.size))

        return Array(foundDevices.values)
    }

    // MARK: - Quick Scan (Background)

    func quickScan() async -> [YeelightDevice] {
        do {
            return try await discoverDevices(timeout: 3.0)
        } catch {
            return []
        }
    }

    // MARK: - Manual Device Addition

    func addManualDevice(ipAddress: String, port: Int = 55443) async throws -> YeelightDevice? {
        let tempDevice = YeelightDevice(
            id: "manual_\(ipAddress)",
            model: "unknown",
            ipAddress: ipAddress,
            port: port,
            name: "Manual Device"
        )

        let connectionManager = YeelightConnectionManager()
        try await connectionManager.connect(to: tempDevice)

        let command = YeelightCommand.getProperties(["model", "name", "fw_ver"])
        let response = try await connectionManager.send(command)

        await connectionManager.disconnect()

        if response.isSuccess {
            return YeelightDevice(
                id: "yeelight_\(ipAddress.replacingOccurrences(of: ".", with: "_"))",
                model: response.result?[0] as? String ?? "unknown",
                ipAddress: ipAddress,
                port: port,
                name: response.result?[1] as? String ?? "Yeelight (\(ipAddress))",
                firmwareVersion: response.result?[2] as? String ?? ""
            )
        }

        return nil
    }

    // MARK: - Verify Device Reachability

    func verifyDevice(_ device: YeelightDevice) async -> Bool {
        let connectionManager = YeelightConnectionManager()
        do {
            try await connectionManager.connect(to: device)
            await connectionManager.disconnect()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Discovery Error

enum DiscoveryError: LocalizedError {
    case noDevicesFound
    case multicastFailed
    case timeout
    case socketCreationFailed
    case bindFailed
    case multicastJoinFailed
    case sendFailed

    var errorDescription: String? {
        switch self {
        case .noDevicesFound:
            return "Hicbir Yeelight cihazi bulunamadi"
        case .multicastFailed:
            return "Multicast arama basarisiz"
        case .timeout:
            return "Arama zaman asimina ugradi"
        case .socketCreationFailed:
            return "Socket olusturulamadi"
        case .bindFailed:
            return "Socket bind hatasi"
        case .multicastJoinFailed:
            return "Multicast grubuna katilamadi"
        case .sendFailed:
            return "Arama mesaji gonderilemedi"
        }
    }
}
