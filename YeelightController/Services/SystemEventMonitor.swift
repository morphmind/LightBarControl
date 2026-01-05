import Foundation
import Cocoa

@MainActor
class SystemEventMonitor: ObservableObject {
    static let shared = SystemEventMonitor()

    @Published var isDisplayAsleep = false
    @Published var isSystemAsleep = false

    // Callbacks
    var onDisplaySleep: (() async -> Void)?
    var onDisplayWake: (() async -> Void)?
    var onSystemSleep: (() async -> Void)?
    var onSystemWake: (() async -> Void)?

    // State restoration
    private var savedLightState: SavedLightState?

    private init() {
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        let center = NSWorkspace.shared.notificationCenter

        // Display sleep/wake
        center.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleDisplaySleep()
            }
        }

        center.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleDisplayWake()
            }
        }

        // System sleep/wake
        center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSystemSleep()
            }
        }

        center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSystemWake()
            }
        }

    }

    // MARK: - Event Handlers

    private func handleDisplaySleep() {
        isDisplayAsleep = true

        Task {
            await onDisplaySleep?()
        }
    }

    private func handleDisplayWake() {
        isDisplayAsleep = false

        Task {
            await onDisplayWake?()
        }
    }

    private func handleSystemSleep() {
        isSystemAsleep = true

        Task {
            await onSystemSleep?()
        }
    }

    private func handleSystemWake() {
        isSystemAsleep = false

        Task {
            await onSystemWake?()
        }
    }

    // MARK: - State Management

    func saveCurrentState(_ state: DeviceState) {
        savedLightState = SavedLightState(
            mainPower: state.mainPower,
            mainBrightness: state.mainBrightness,
            colorTemperature: state.colorTemperature,
            bgPower: state.bgPower,
            bgBrightness: state.bgBrightness,
            bgRGB: state.bgRGB,
            savedAt: Date()
        )
    }

    func getSavedState() -> SavedLightState? {
        return savedLightState
    }

    func clearSavedState() {
        savedLightState = nil
    }
}

// MARK: - Saved Light State

struct SavedLightState {
    let mainPower: Bool
    let mainBrightness: Int
    let colorTemperature: Int
    let bgPower: Bool
    let bgBrightness: Int
    let bgRGB: Int
    let savedAt: Date
}
