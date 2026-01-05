import Foundation

struct LightPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var mainPower: Bool
    var mainBrightness: Int
    var colorTemperature: Int
    var bgPower: Bool
    var bgBrightness: Int
    var bgRGB: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        mainPower: Bool = true,
        mainBrightness: Int = 80,
        colorTemperature: Int = 4500,
        bgPower: Bool = false,
        bgBrightness: Int = 50,
        bgRGB: Int = 16744192,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.mainPower = mainPower
        self.mainBrightness = mainBrightness
        self.colorTemperature = colorTemperature
        self.bgPower = bgPower
        self.bgBrightness = bgBrightness
        self.bgRGB = bgRGB
        self.createdAt = createdAt
    }

    static func fromState(_ state: DeviceState, name: String) -> LightPreset {
        LightPreset(
            name: name,
            mainPower: state.mainPower,
            mainBrightness: state.mainBrightness,
            colorTemperature: state.colorTemperature,
            bgPower: state.bgPower,
            bgBrightness: state.bgBrightness,
            bgRGB: state.bgRGB
        )
    }

    func toState() -> DeviceState {
        DeviceState(
            mainPower: mainPower,
            mainBrightness: mainBrightness,
            colorTemperature: colorTemperature,
            bgPower: bgPower,
            bgBrightness: bgBrightness,
            bgRGB: bgRGB
        )
    }
}

// MARK: - Default Presets
extension LightPreset {
    static let reading = LightPreset(
        name: "Okuma",
        mainPower: true,
        mainBrightness: 80,
        colorTemperature: 4500,
        bgPower: false,
        bgBrightness: 0,
        bgRGB: 0
    )

    static let gaming = LightPreset(
        name: "Oyun",
        mainPower: true,
        mainBrightness: 60,
        colorTemperature: 4000,
        bgPower: true,
        bgBrightness: 50,
        bgRGB: 255 // Blue
    )

    static let night = LightPreset(
        name: "Gece",
        mainPower: true,
        mainBrightness: 30,
        colorTemperature: 2700,
        bgPower: true,
        bgBrightness: 20,
        bgRGB: 16744192 // Orange #FF6B00
    )

    static let focus = LightPreset(
        name: "Odaklanma",
        mainPower: true,
        mainBrightness: 100,
        colorTemperature: 5000,
        bgPower: false,
        bgBrightness: 0,
        bgRGB: 0
    )

    static let defaults: [LightPreset] = [.reading, .gaming, .night, .focus]
}
