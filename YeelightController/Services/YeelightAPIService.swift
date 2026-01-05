import Foundation
import Combine

@MainActor
class YeelightAPIService: ObservableObject {
    private let connectionManager = YeelightConnectionManager()
    private var pollingTask: Task<Void, Never>?

    @Published var currentState: DeviceState?
    @Published var isConnected: Bool = false
    @Published var lastError: Error?
    @Published var currentDevice: YeelightDevice?

    private let propertiesToFetch = ["power", "bright", "ct", "bg_power", "bg_bright", "bg_rgb"]
    private var lastCommandTime: Date = .distantPast
    private let commandCooldown: TimeInterval = 2.0

    // MARK: - Connection

    func connect(to device: YeelightDevice) async {
        do {
            try await connectionManager.connect(to: device)
            currentDevice = device
            isConnected = await connectionManager.isConnected
            lastError = nil

            await connectionManager.setNotificationHandler { [weak self] response in
                Task { @MainActor in
                    self?.handleNotification(response)
                }
            }

            try await refreshState()
            startPolling()
        } catch {
            lastError = error
            isConnected = false
        }
    }

    func disconnect() async {
        stopPolling()
        await connectionManager.disconnect()
        isConnected = false
        currentDevice = nil
        currentState = nil
    }

    // MARK: - Main Light Controls

    func setMainPower(_ on: Bool) async throws {
        lastCommandTime = Date()
        let command = YeelightCommand.setPower(on)
        let response = try await connectionManager.send(command)
        if response.isSuccess {
            currentState?.mainPower = on
        }
    }

    func setMainBrightness(_ value: Int) async throws {
        let command = YeelightCommand.setBrightness(value)
        _ = try await connectionManager.send(command)
        currentState?.mainBrightness = value
    }

    func setColorTemperature(_ kelvin: Int) async throws {
        let command = YeelightCommand.setColorTemperature(kelvin)
        _ = try await connectionManager.send(command)
        currentState?.colorTemperature = kelvin
    }

    func toggleMain() async throws {
        let command = YeelightCommand.toggle()
        _ = try await connectionManager.send(command)
        currentState?.mainPower.toggle()
    }

    // MARK: - Background Light Controls

    func setBgPower(_ on: Bool) async throws {
        lastCommandTime = Date()
        let command = YeelightCommand.bgSetPower(on)
        let response = try await connectionManager.send(command)
        if response.isSuccess {
            currentState?.bgPower = on
        }
    }

    func setBgBrightness(_ value: Int) async throws {
        let command = YeelightCommand.bgSetBrightness(value)
        _ = try await connectionManager.send(command)
        currentState?.bgBrightness = value
    }

    func setBgColor(red: Int, green: Int, blue: Int) async throws {
        let rgb = DeviceState.rgbToInt(red: red, green: green, blue: blue)
        try await setBgColor(rgb: rgb)
    }

    func setBgColor(rgb: Int) async throws {
        let command = YeelightCommand.bgSetRGB(rgb)
        _ = try await connectionManager.send(command)
        currentState?.bgRGB = rgb
    }

    func toggleBg() async throws {
        let command = YeelightCommand.bgToggle()
        _ = try await connectionManager.send(command)
        currentState?.bgPower.toggle()
    }

    // MARK: - Timer

    func setSleepTimer(minutes: Int) async throws {
        let command = YeelightCommand.cronAdd(minutes: minutes)
        _ = try await connectionManager.send(command)
        currentState?.timerMinutesRemaining = minutes
    }

    func cancelSleepTimer() async throws {
        let command = YeelightCommand.cronDelete()
        _ = try await connectionManager.send(command)
        currentState?.timerMinutesRemaining = nil
    }

    // MARK: - Utilities

    func refreshState() async throws {
        let timeSinceLastCommand = Date().timeIntervalSince(lastCommandTime)
        if timeSinceLastCommand < commandCooldown {
            return
        }

        let command = YeelightCommand.getProperties(propertiesToFetch)
        let response = try await connectionManager.send(command)

        let props = response.propertiesAsDictionary(for: propertiesToFetch)
        let newState = DeviceState.fromProperties(props)
        currentState = newState
    }

    func saveAsDefault() async throws {
        let command = YeelightCommand.setDefault()
        _ = try await connectionManager.send(command)
    }

    func applyPreset(_ preset: LightPreset) async throws {
        if preset.mainPower {
            try await setMainPower(true)
            try await setMainBrightness(preset.mainBrightness)
            try await setColorTemperature(preset.colorTemperature)
        } else {
            try await setMainPower(false)
        }

        if preset.bgPower {
            try await setBgPower(true)
            try await setBgBrightness(preset.bgBrightness)
            try await setBgColor(rgb: preset.bgRGB)
        } else {
            try await setBgPower(false)
        }
    }

    // MARK: - Polling

    private func startPolling(interval: TimeInterval = 5.0) {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { break }

                do {
                    try await refreshState()
                } catch {
                    if await !connectionManager.isConnected {
                        isConnected = false
                        break
                    }
                }
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Notification Handling

    private func handleNotification(_ response: YeelightResponse) {
        guard let params = response.params else { return }

        let timeSinceLastCommand = Date().timeIntervalSince(lastCommandTime)
        if timeSinceLastCommand < commandCooldown {
            return
        }

        if let power = params["power"] as? String {
            currentState?.mainPower = power == "on"
        }
        if let bright = params["bright"] as? String, let value = Int(bright) {
            currentState?.mainBrightness = value
        }
        if let ct = params["ct"] as? String, let value = Int(ct) {
            currentState?.colorTemperature = value
        }
        if let bgPower = params["bg_power"] as? String {
            currentState?.bgPower = bgPower == "on"
        }
        if let bgBright = params["bg_bright"] as? String, let value = Int(bgBright) {
            currentState?.bgBrightness = value
        }
        if let bgRgb = params["bg_rgb"] as? String, let value = Int(bgRgb) {
            currentState?.bgRGB = value
        }
    }
}
