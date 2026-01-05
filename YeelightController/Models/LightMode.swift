import Foundation
import SwiftUI

struct LightMode: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String  // SF Symbol name
    var description: String  // Mode description
    var mainPower: Bool
    var mainBrightness: Int  // 1-100
    var colorTemperature: Int  // 2700-6500K
    var bgPower: Bool
    var bgBrightness: Int  // 1-100
    var bgRGB: Int  // RGB as single int
    var isFavorite: Bool
    var isBuiltIn: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        description: String = "",
        mainPower: Bool = true,
        mainBrightness: Int = 80,
        colorTemperature: Int = 4500,
        bgPower: Bool = false,
        bgBrightness: Int = 50,
        bgRGB: Int = 0xFFFFFF,
        isFavorite: Bool = false,
        isBuiltIn: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.mainPower = mainPower
        self.mainBrightness = mainBrightness
        self.colorTemperature = colorTemperature
        self.bgPower = bgPower
        self.bgBrightness = bgBrightness
        self.bgRGB = bgRGB
        self.isFavorite = isFavorite
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var bgColor: Color {
        let red = Double((bgRGB >> 16) & 0xFF) / 255.0
        let green = Double((bgRGB >> 8) & 0xFF) / 255.0
        let blue = Double(bgRGB & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }

    var colorTemperatureDescription: String {
        if colorTemperature <= 3000 {
            return "Sicak"
        } else if colorTemperature <= 4500 {
            return "Dogal"
        } else {
            return "Soguk"
        }
    }

    // MARK: - Create from current state

    static func fromState(_ state: DeviceState, name: String, icon: String, description: String = "") -> LightMode {
        LightMode(
            name: name,
            icon: icon,
            description: description,
            mainPower: state.mainPower,
            mainBrightness: state.mainBrightness,
            colorTemperature: state.colorTemperature,
            bgPower: state.bgPower,
            bgBrightness: state.bgBrightness,
            bgRGB: state.bgRGB,
            isFavorite: false,
            isBuiltIn: false
        )
    }

    // MARK: - Default Modes (9 adet)

    static let defaults: [LightMode] = [
        // Work - Maximum focus
        LightMode(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            name: "Work",
            icon: "briefcase.fill",
            description: "Maximum brightness with cool white light for focused work and productivity",
            mainPower: true,
            mainBrightness: 100,
            colorTemperature: 5500,
            bgPower: false,
            bgBrightness: 0,
            bgRGB: 0xFFFFFF,
            isFavorite: true,
            isBuiltIn: true
        ),
        // Cinema - Movie watching
        LightMode(
            id: UUID(uuidString: "00000002-0000-0000-0000-000000000002")!,
            name: "Cinema",
            icon: "film.fill",
            description: "Low warm light with blue ambient glow, perfect for watching movies",
            mainPower: true,
            mainBrightness: 20,
            colorTemperature: 2700,
            bgPower: true,
            bgBrightness: 30,
            bgRGB: 0x0066FF,
            isFavorite: true,
            isBuiltIn: true
        ),
        // Relaxing - Evening rest
        LightMode(
            id: UUID(uuidString: "00000003-0000-0000-0000-000000000003")!,
            name: "Relax",
            icon: "moon.fill",
            description: "Soft warm lighting with orange ambient for evening relaxation",
            mainPower: true,
            mainBrightness: 50,
            colorTemperature: 3500,
            bgPower: true,
            bgBrightness: 20,
            bgRGB: 0xFF8C00,
            isFavorite: true,
            isBuiltIn: true
        ),
        // Sleep - Before bed
        LightMode(
            id: UUID(uuidString: "00000004-0000-0000-0000-000000000004")!,
            name: "Sleep",
            icon: "bed.double.fill",
            description: "Very dim warm light to prepare your eyes for sleep",
            mainPower: true,
            mainBrightness: 30,
            colorTemperature: 2700,
            bgPower: false,
            bgBrightness: 0,
            bgRGB: 0xFFFFFF,
            isFavorite: true,
            isBuiltIn: true
        ),
        // Gaming
        LightMode(
            id: UUID(uuidString: "00000005-0000-0000-0000-000000000005")!,
            name: "Gaming",
            icon: "gamecontroller.fill",
            description: "Balanced lighting with purple ambient for immersive gaming sessions",
            mainPower: true,
            mainBrightness: 60,
            colorTemperature: 4000,
            bgPower: true,
            bgBrightness: 50,
            bgRGB: 0x9932CC,
            isFavorite: false,
            isBuiltIn: true
        ),
        // Reading
        LightMode(
            id: UUID(uuidString: "00000006-0000-0000-0000-000000000006")!,
            name: "Reading",
            icon: "book.fill",
            description: "Bright neutral light optimized for reading books and documents",
            mainPower: true,
            mainBrightness: 80,
            colorTemperature: 4500,
            bgPower: false,
            bgBrightness: 0,
            bgRGB: 0xFFFFFF,
            isFavorite: false,
            isBuiltIn: true
        ),
        // Meeting - Video conference
        LightMode(
            id: UUID(uuidString: "00000007-0000-0000-0000-000000000007")!,
            name: "Meeting",
            icon: "person.2.fill",
            description: "High brightness daylight for video conferences and calls",
            mainPower: true,
            mainBrightness: 90,
            colorTemperature: 5000,
            bgPower: false,
            bgBrightness: 0,
            bgRGB: 0xFFFFFF,
            isFavorite: false,
            isBuiltIn: true
        ),
        // Presentation
        LightMode(
            id: UUID(uuidString: "00000008-0000-0000-0000-000000000008")!,
            name: "Present",
            icon: "tv.fill",
            description: "Maximum cool light for screen sharing and presentations",
            mainPower: true,
            mainBrightness: 100,
            colorTemperature: 6000,
            bgPower: false,
            bgBrightness: 0,
            bgRGB: 0xFFFFFF,
            isFavorite: false,
            isBuiltIn: true
        ),
        // Meditation
        LightMode(
            id: UUID(uuidString: "00000009-0000-0000-0000-000000000009")!,
            name: "Meditate",
            icon: "leaf.fill",
            description: "Very dim warm light with soft orange glow for meditation and mindfulness",
            mainPower: true,
            mainBrightness: 15,
            colorTemperature: 2700,
            bgPower: true,
            bgBrightness: 10,
            bgRGB: 0xFF6B35,
            isFavorite: false,
            isBuiltIn: true
        )
    ]

    static let defaultFavorites: [LightMode] = defaults.filter { $0.isFavorite }
}
