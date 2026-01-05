import Foundation
import SwiftUI

struct DeviceState: Equatable {
    // Main light
    var mainPower: Bool
    var mainBrightness: Int  // 1-100
    var colorTemperature: Int // 2700-6500 Kelvin

    // Background/Ambient light
    var bgPower: Bool
    var bgBrightness: Int    // 1-100
    var bgRGB: Int           // RGB as single integer (0-16777215)

    // Timer
    var timerMinutesRemaining: Int?

    // Computed RGB components
    var bgRed: Int { (bgRGB >> 16) & 0xFF }
    var bgGreen: Int { (bgRGB >> 8) & 0xFF }
    var bgBlue: Int { bgRGB & 0xFF }

    var bgColor: Color {
        Color(red: Double(bgRed) / 255.0, green: Double(bgGreen) / 255.0, blue: Double(bgBlue) / 255.0)
    }

    init(
        mainPower: Bool = false,
        mainBrightness: Int = 80,
        colorTemperature: Int = 4500,
        bgPower: Bool = false,
        bgBrightness: Int = 50,
        bgRGB: Int = 16744192 // Orange #FF6B00
    ) {
        self.mainPower = mainPower
        self.mainBrightness = mainBrightness
        self.colorTemperature = colorTemperature
        self.bgPower = bgPower
        self.bgBrightness = bgBrightness
        self.bgRGB = bgRGB
        self.timerMinutesRemaining = nil
    }

    static func fromProperties(_ props: [String: Any]) -> DeviceState {
        var state = DeviceState()

        if let power = props["power"] as? String {
            state.mainPower = power == "on"
        }
        if let bright = props["bright"] as? Int {
            state.mainBrightness = bright
        } else if let bright = props["bright"] as? String, let value = Int(bright) {
            state.mainBrightness = value
        }
        if let ct = props["ct"] as? Int {
            state.colorTemperature = ct
        } else if let ct = props["ct"] as? String, let value = Int(ct) {
            state.colorTemperature = value
        }
        if let bgPower = props["bg_power"] as? String {
            state.bgPower = bgPower == "on"
        }
        if let bgBright = props["bg_bright"] as? Int {
            state.bgBrightness = bgBright
        } else if let bgBright = props["bg_bright"] as? String, let value = Int(bgBright) {
            state.bgBrightness = value
        }
        if let bgRgb = props["bg_rgb"] as? Int {
            state.bgRGB = bgRgb
        } else if let bgRgb = props["bg_rgb"] as? String, let value = Int(bgRgb) {
            state.bgRGB = value
        }

        return state
    }

    static func rgbToInt(red: Int, green: Int, blue: Int) -> Int {
        return (red << 16) | (green << 8) | blue
    }

    static func colorToRGBInt(_ color: Color) -> Int {
        let nsColor = NSColor(color)
        guard let rgb = nsColor.usingColorSpace(.deviceRGB) else { return 0 }
        let red = Int(rgb.redComponent * 255)
        let green = Int(rgb.greenComponent * 255)
        let blue = Int(rgb.blueComponent * 255)
        return rgbToInt(red: red, green: green, blue: blue)
    }
}
