import Foundation
import SwiftUI
import ServiceManagement

@MainActor
class SettingsService: ObservableObject {
    // MARK: - App Settings

    @AppStorage("selectedDeviceId") var selectedDeviceId: String = ""
    @AppStorage("autoConnect") var autoConnect: Bool = true
    @AppStorage("autoDiscovery") var autoDiscovery: Bool = true
    @AppStorage("pollingInterval") var pollingInterval: Double = 5.0

    // MARK: - Automation Settings

    @AppStorage("turnOffOnSleep") var turnOffOnSleep: Bool = true
    @AppStorage("restoreOnWake") var restoreOnWake: Bool = true
    @AppStorage("schedulesEnabled") var schedulesEnabled: Bool = true

    // MARK: - Modes

    @Published var modes: [LightMode] = []
    @Published var favoriteModeIds: [UUID] = []
    private let modesKey = "lightModes"
    private let favoritesKey = "favoriteModeIds"

    // MARK: - Presets (Legacy - keeping for migration)

    @Published var presets: [LightPreset] = []
    private let presetsKey = "savedPresets"

    // MARK: - Known Devices

    @Published var knownDevices: [YeelightDevice] = []
    private let devicesKey = "knownDevices"

    // MARK: - Launch at Login

    var launchAtLogin: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
            }
        }
    }

    // MARK: - Initialization

    init() {
        loadModes()
        loadPresets()
        loadKnownDevices()
    }

    // MARK: - Mode Management

    func loadModes() {
        if let data = UserDefaults.standard.data(forKey: modesKey),
           let savedModes = try? JSONDecoder().decode([LightMode].self, from: data) {
            modes = savedModes
        } else {
            // Load default modes on first run
            modes = LightMode.defaults
            saveModes()
        }

        // Load favorites
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let savedFavorites = try? JSONDecoder().decode([UUID].self, from: data) {
            favoriteModeIds = savedFavorites
        } else {
            // Default favorites (first 4)
            favoriteModeIds = LightMode.defaultFavorites.map { $0.id }
            saveFavorites()
        }
    }

    private func saveModes() {
        if let data = try? JSONEncoder().encode(modes) {
            UserDefaults.standard.set(data, forKey: modesKey)
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteModeIds) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }

    func addMode(_ mode: LightMode) {
        modes.append(mode)
        saveModes()
    }

    func updateMode(_ mode: LightMode) {
        if let index = modes.firstIndex(where: { $0.id == mode.id }) {
            modes[index] = mode
            saveModes()
        }
    }

    func deleteMode(_ id: UUID) {
        // Don't delete built-in modes
        guard let mode = modes.first(where: { $0.id == id }), !mode.isBuiltIn else { return }
        modes.removeAll { $0.id == id }
        favoriteModeIds.removeAll { $0 == id }
        saveModes()
        saveFavorites()
    }

    func getMode(by id: UUID) -> LightMode? {
        modes.first { $0.id == id }
    }

    func getFavoriteModes() -> [LightMode] {
        favoriteModeIds.compactMap { id in
            modes.first { $0.id == id }
        }
    }

    func setFavorites(_ ids: [UUID]) {
        favoriteModeIds = Array(ids.prefix(4))  // Max 4 favorites
        saveFavorites()
    }

    func toggleFavorite(_ id: UUID) {
        if favoriteModeIds.contains(id) {
            favoriteModeIds.removeAll { $0 == id }
        } else if favoriteModeIds.count < 4 {
            favoriteModeIds.append(id)
        }
        saveFavorites()
    }

    func saveCurrentStateAsMode(_ state: DeviceState, name: String, icon: String, description: String = "") {
        let mode = LightMode.fromState(state, name: name, icon: icon, description: description)
        addMode(mode)
    }

    func resetModesToDefaults() {
        modes = LightMode.defaults
        favoriteModeIds = LightMode.defaultFavorites.map { $0.id }
        saveModes()
        saveFavorites()
    }

    // MARK: - Preset Management (Legacy)

    func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: presetsKey),
           let savedPresets = try? JSONDecoder().decode([LightPreset].self, from: data) {
            presets = savedPresets
        } else {
            // Load default presets on first run
            presets = LightPreset.defaults
            savePresets()
        }
    }

    private func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: presetsKey)
        }
    }

    func addPreset(_ preset: LightPreset) {
        presets.append(preset)
        savePresets()
    }

    func updatePreset(_ preset: LightPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            savePresets()
        }
    }

    func deletePreset(_ id: UUID) {
        presets.removeAll { $0.id == id }
        savePresets()
    }

    func saveCurrentState(_ state: DeviceState, name: String) {
        let preset = LightPreset.fromState(state, name: name)
        addPreset(preset)
    }

    // MARK: - Device Management

    func loadKnownDevices() {
        if let data = UserDefaults.standard.data(forKey: devicesKey),
           let devices = try? JSONDecoder().decode([YeelightDevice].self, from: data) {
            knownDevices = devices
        }
    }

    private func saveKnownDevices() {
        if let data = try? JSONEncoder().encode(knownDevices) {
            UserDefaults.standard.set(data, forKey: devicesKey)
        }
    }

    func cacheDevice(_ device: YeelightDevice) {
        if let index = knownDevices.firstIndex(where: { $0.id == device.id }) {
            knownDevices[index] = device
        } else {
            knownDevices.append(device)
        }
        saveKnownDevices()
    }

    func removeDevice(_ id: String) {
        knownDevices.removeAll { $0.id == id }
        saveKnownDevices()
    }

    func getLastConnectedDevice() -> YeelightDevice? {
        knownDevices.first { $0.id == selectedDeviceId }
    }

    // MARK: - Reset

    func resetToDefaults() {
        // Reset modes
        resetModesToDefaults()

        // Reset presets
        presets = LightPreset.defaults
        savePresets()

        // Reset settings
        selectedDeviceId = ""
        autoConnect = true
        autoDiscovery = true
        pollingInterval = 5.0
        turnOffOnSleep = true
        restoreOnWake = true
        schedulesEnabled = true
    }
}
