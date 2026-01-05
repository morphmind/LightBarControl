import Foundation
import SwiftUI
import Combine

@MainActor
class DeviceViewModel: ObservableObject {
    private let apiService = YeelightAPIService()
    private let discoveryService = DeviceDiscoveryService()

    @Published var device: YeelightDevice?
    @Published var state: DeviceState?
    @Published var isConnecting: Bool = false
    @Published var isConnected: Bool = false
    @Published var isDiscovering: Bool = false
    @Published var discoveredDevices: [YeelightDevice] = []
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    @Published var timerMinutes: Int = 0
    @Published var isTimerActive: Bool = false

    private var brightnessDebounceTask: Task<Void, Never>?
    private var colorTempDebounceTask: Task<Void, Never>?
    private var bgBrightnessDebounceTask: Task<Void, Never>?
    private var bgColorDebounceTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        apiService.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)

        apiService.$currentState
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)

        apiService.$currentDevice
            .receive(on: DispatchQueue.main)
            .assign(to: &$device)

        apiService.$lastError
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.localizedDescription }
            .sink { [weak self] error in
                self?.showErrorMessage(error)
            }
            .store(in: &cancellables)
    }

    // MARK: - Connection

    func connect(to device: YeelightDevice) async {
        isConnecting = true
        errorMessage = nil

        await apiService.connect(to: device)

        isConnecting = false

        if !isConnected {
            showErrorMessage("Could not connect to device")
        }
    }

    func disconnect() async {
        await apiService.disconnect()
    }

    func autoConnect(using settings: SettingsService) async {
        guard settings.autoConnect,
              let device = settings.getLastConnectedDevice() else {
            return
        }

        await connect(to: device)

        if isConnected {
            settings.cacheDevice(device)
        }
    }

    // MARK: - Discovery

    func discoverDevices() async {
        isDiscovering = true
        discoveredDevices = []

        do {
            let devices = try await discoveryService.discoverDevices(timeout: 5.0)
            discoveredDevices = devices

            if devices.isEmpty {
                showErrorMessage("No devices found. Make sure LAN Control is enabled.")
            }
        } catch {
            showErrorMessage("Search error: \(error.localizedDescription)")
        }

        isDiscovering = false
    }

    func addManualDevice(ip: String) async -> Bool {
        do {
            if let device = try await discoveryService.addManualDevice(ipAddress: ip) {
                discoveredDevices.append(device)
                return true
            }
        } catch {
            showErrorMessage("Could not add device: \(error.localizedDescription)")
        }
        return false
    }

    // MARK: - Main Light Controls

    func toggleMainPower() async {
        guard isConnected else { return }

        do {
            try await apiService.toggleMain()
        } catch {
            showErrorMessage("Light toggle error")
        }
    }

    func setMainPower(_ on: Bool) async {
        guard isConnected else { return }

        do {
            try await apiService.setMainPower(on)
        } catch {
            showErrorMessage("Light control error")
        }
    }

    func updateMainBrightness(_ value: Int) {
        brightnessDebounceTask?.cancel()
        brightnessDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, isConnected else { return }

            do {
                try await apiService.setMainBrightness(value)
            } catch {
                showErrorMessage("Brightness error")
            }
        }
    }

    func updateColorTemperature(_ value: Int) {
        colorTempDebounceTask?.cancel()
        colorTempDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, isConnected else { return }

            do {
                try await apiService.setColorTemperature(value)
            } catch {
                showErrorMessage("Color temperature error")
            }
        }
    }

    // MARK: - Background Light Controls

    func toggleBgPower() async {
        guard isConnected else { return }

        do {
            try await apiService.toggleBg()
        } catch {
            showErrorMessage("Ambient light toggle error")
        }
    }

    func setBgPower(_ on: Bool) async {
        guard isConnected else { return }

        do {
            try await apiService.setBgPower(on)
        } catch {
            showErrorMessage("Ambient light control error")
        }
    }

    func updateBgBrightness(_ value: Int) {
        bgBrightnessDebounceTask?.cancel()
        bgBrightnessDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, isConnected else { return }

            do {
                try await apiService.setBgBrightness(value)
            } catch {
                showErrorMessage("Ambient brightness error")
            }
        }
    }

    func updateBgColor(_ color: Color) {
        let rgb = DeviceState.colorToRGBInt(color)

        if state != nil {
            state?.bgRGB = rgb
        }

        bgColorDebounceTask?.cancel()
        bgColorDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled, isConnected else { return }

            do {
                try await apiService.setBgColor(rgb: rgb)
            } catch {
                showErrorMessage("Ambient color error")
            }
        }
    }

    func setBgColorDirect(_ rgb: Int) {
        if state != nil {
            state?.bgRGB = rgb
        }

        bgColorDebounceTask?.cancel()
        bgColorDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled, isConnected else { return }

            do {
                try await apiService.setBgColor(rgb: rgb)
            } catch {
                showErrorMessage("Ambient color error")
            }
        }
    }

    // MARK: - Timer

    func setTimer(minutes: Int) async {
        guard isConnected, minutes > 0 else { return }

        do {
            try await apiService.setSleepTimer(minutes: minutes)
            timerMinutes = minutes
            isTimerActive = true
        } catch {
            showErrorMessage("Timer error")
        }
    }

    func cancelTimer() async {
        guard isConnected else { return }

        do {
            try await apiService.cancelSleepTimer()
            timerMinutes = 0
            isTimerActive = false
        } catch {
            showErrorMessage("Timer cancel error")
        }
    }

    // MARK: - Presets

    func applyPreset(_ preset: LightPreset) async {
        guard isConnected else { return }

        do {
            try await apiService.applyPreset(preset)
        } catch {
            showErrorMessage("Preset error")
        }
    }

    func saveAsDefault() async {
        guard isConnected else { return }

        do {
            try await apiService.saveAsDefault()
        } catch {
            showErrorMessage("Save default error")
        }
    }

    // MARK: - Modes

    func applyMode(_ mode: LightMode) async {
        guard isConnected else { return }

        do {
            try await apiService.setMainPower(mode.mainPower)

            if mode.mainPower {
                try await apiService.setMainBrightness(mode.mainBrightness)
                try await apiService.setColorTemperature(mode.colorTemperature)
            }

            try await apiService.setBgPower(mode.bgPower)

            if mode.bgPower {
                try await apiService.setBgBrightness(mode.bgBrightness)
                try await apiService.setBgColor(rgb: mode.bgRGB)
            }

        } catch {
            showErrorMessage("Mode error")
        }
    }

    // MARK: - Quick Actions

    func turnOffAllLights() async {
        guard isConnected else { return }

        do {
            try await apiService.setMainPower(false)
            try await apiService.setBgPower(false)
        } catch {
            showErrorMessage("Turn off error")
        }
    }

    func restoreState(_ savedState: SavedLightState) async {
        guard isConnected else { return }

        do {
            try await apiService.setMainPower(savedState.mainPower)
            if savedState.mainPower {
                try await apiService.setMainBrightness(savedState.mainBrightness)
                try await apiService.setColorTemperature(savedState.colorTemperature)
            }

            try await apiService.setBgPower(savedState.bgPower)
            if savedState.bgPower {
                try await apiService.setBgBrightness(savedState.bgBrightness)
                try await apiService.setBgColor(rgb: savedState.bgRGB)
            }

        } catch {
            showErrorMessage("Restore state error")
        }
    }

    // MARK: - Background Discovery

    func backgroundDiscovery() async -> [YeelightDevice] {
        return await discoveryService.quickScan()
    }

    // MARK: - Refresh

    func refreshState() async {
        guard isConnected else { return }

        do {
            try await apiService.refreshState()
        } catch {
            showErrorMessage("Refresh error")
        }
    }

    // MARK: - Error Handling

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showError = false
        }
    }
}
