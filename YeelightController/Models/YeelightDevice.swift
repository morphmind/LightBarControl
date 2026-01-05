import Foundation

struct YeelightDevice: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let model: String
    var ipAddress: String
    var port: Int
    var name: String
    var firmwareVersion: String
    var supportedMethods: [String]

    var endpoint: String {
        "\(ipAddress):\(port)"
    }

    init(id: String, model: String, ipAddress: String, port: Int = 55443, name: String = "Yeelight", firmwareVersion: String = "", supportedMethods: [String] = []) {
        self.id = id
        self.model = model
        self.ipAddress = ipAddress
        self.port = port
        self.name = name
        self.firmwareVersion = firmwareVersion
        self.supportedMethods = supportedMethods
    }

    static func fromDiscoveryResponse(_ response: String) -> YeelightDevice? {
        var id = ""
        var model = ""
        var ipAddress = ""
        var port = 55443
        var name = "Yeelight"
        var firmwareVersion = ""
        var supportedMethods: [String] = []

        let lines = response.components(separatedBy: "\r\n")

        for line in lines {
            let parts = line.components(separatedBy: ": ")
            guard parts.count >= 2 else { continue }

            let key = parts[0].lowercased()
            let value = parts.dropFirst().joined(separator: ": ")

            switch key {
            case "id":
                id = value
            case "model":
                model = value
            case "location":
                // yeelight://192.168.1.100:55443
                if let url = URL(string: value),
                   let host = url.host {
                    ipAddress = host
                    port = url.port ?? 55443
                }
            case "name":
                if !value.isEmpty {
                    name = value
                }
            case "fw_ver":
                firmwareVersion = value
            case "support":
                supportedMethods = value.components(separatedBy: " ")
            default:
                break
            }
        }

        guard !id.isEmpty, !ipAddress.isEmpty else { return nil }

        return YeelightDevice(
            id: id,
            model: model,
            ipAddress: ipAddress,
            port: port,
            name: name,
            firmwareVersion: firmwareVersion,
            supportedMethods: supportedMethods
        )
    }
}
