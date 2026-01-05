import Foundation

struct YeelightCommand: Encodable {
    let id: Int
    let method: String
    let params: [AnyEncodable]

    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str + "\r\n"
    }
}

// MARK: - Command Factory Methods
extension YeelightCommand {
    private static var commandId = 0

    private static func nextId() -> Int {
        commandId += 1
        return commandId
    }

    // MARK: Main Light Commands

    static func setPower(_ on: Bool, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        YeelightCommand(
            id: nextId(),
            method: "set_power",
            params: [AnyEncodable(on ? "on" : "off"), AnyEncodable(effect), AnyEncodable(duration)]
        )
    }

    static func setBrightness(_ value: Int, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        let brightness = max(1, min(100, value))
        return YeelightCommand(
            id: nextId(),
            method: "set_bright",
            params: [AnyEncodable(brightness), AnyEncodable(effect), AnyEncodable(duration)]
        )
    }

    static func setColorTemperature(_ kelvin: Int, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        let ct = max(2700, min(6500, kelvin))
        return YeelightCommand(
            id: nextId(),
            method: "set_ct_abx",
            params: [AnyEncodable(ct), AnyEncodable(effect), AnyEncodable(duration)]
        )
    }

    static func toggle() -> YeelightCommand {
        YeelightCommand(id: nextId(), method: "toggle", params: [])
    }

    // MARK: Background Light Commands

    static func bgSetPower(_ on: Bool, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        YeelightCommand(
            id: nextId(),
            method: "bg_set_power",
            params: [AnyEncodable(on ? "on" : "off"), AnyEncodable(effect), AnyEncodable(duration)]
        )
    }

    static func bgSetBrightness(_ value: Int, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        let brightness = max(1, min(100, value))
        return YeelightCommand(
            id: nextId(),
            method: "bg_set_bright",
            params: [AnyEncodable(brightness), AnyEncodable(effect), AnyEncodable(duration)]
        )
    }

    static func bgSetRGB(_ rgb: Int, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        let rgbValue = max(0, min(16777215, rgb))
        return YeelightCommand(
            id: nextId(),
            method: "bg_set_rgb",
            params: [AnyEncodable(rgbValue), AnyEncodable(effect), AnyEncodable(duration)]
        )
    }

    static func bgToggle() -> YeelightCommand {
        YeelightCommand(id: nextId(), method: "bg_toggle", params: [])
    }

    // MARK: Timer Commands

    static func cronAdd(minutes: Int) -> YeelightCommand {
        // type 0 = power off timer
        YeelightCommand(
            id: nextId(),
            method: "cron_add",
            params: [AnyEncodable(0), AnyEncodable(minutes)]
        )
    }

    static func cronDelete() -> YeelightCommand {
        YeelightCommand(
            id: nextId(),
            method: "cron_del",
            params: [AnyEncodable(0)]
        )
    }

    static func cronGet() -> YeelightCommand {
        YeelightCommand(
            id: nextId(),
            method: "cron_get",
            params: [AnyEncodable(0)]
        )
    }

    // MARK: Utility Commands

    static func getProperties(_ props: [String] = ["power", "bright", "ct", "bg_power", "bg_bright", "bg_rgb"]) -> YeelightCommand {
        YeelightCommand(
            id: nextId(),
            method: "get_prop",
            params: props.map { AnyEncodable($0) }
        )
    }

    static func setDefault() -> YeelightCommand {
        YeelightCommand(id: nextId(), method: "set_default", params: [])
    }

    static func setName(_ name: String) -> YeelightCommand {
        YeelightCommand(
            id: nextId(),
            method: "set_name",
            params: [AnyEncodable(name)]
        )
    }
}

// MARK: - AnyEncodable Wrapper
struct AnyEncodable: Encodable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else {
            try container.encodeNil()
        }
    }
}
