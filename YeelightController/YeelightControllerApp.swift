import SwiftUI

@main
struct YeelightControllerApp: App {
    @StateObject private var deviceViewModel = DeviceViewModel()
    @StateObject private var settingsService = SettingsService()
    @StateObject private var scheduleManager = ScheduleManager()

    init() {
        // Setup will happen in onAppear of the view
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
                .environmentObject(deviceViewModel)
                .environmentObject(settingsService)
                .environmentObject(scheduleManager)
                .frame(width: 320, height: 600)
                .onAppear {
                    setupApp()
                }
        } label: {
            Image(systemName: menuBarIcon)
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(deviceViewModel)
                .environmentObject(settingsService)
                .environmentObject(scheduleManager)
        }
    }

    private var menuBarIcon: String {
        if deviceViewModel.isConnected {
            return deviceViewModel.state?.mainPower == true ? "lightbulb.fill" : "lightbulb"
        } else {
            return "lightbulb.slash"
        }
    }

    private func setupApp() {
        // Setup system event monitor
        setupSystemEventMonitor()

        // Setup schedule manager callbacks
        setupScheduleManager()

        // Auto discovery and connection
        Task {
            await performStartupTasks()
        }
    }

    private func setupSystemEventMonitor() {
        let monitor = SystemEventMonitor.shared
        let viewModel = deviceViewModel
        let settings = settingsService

        // When display sleeps
        monitor.onDisplaySleep = {
            guard settings.turnOffOnSleep else {
                return
            }

            // Save current state before turning off
            if let state = viewModel.state {
                monitor.saveCurrentState(state)
            }

            // Turn off lights
            await viewModel.turnOffAllLights()
        }

        // When display wakes
        monitor.onDisplayWake = {
            guard settings.restoreOnWake else {
                return
            }

            // Small delay to ensure connection is ready
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Restore previous state
            if let savedState = monitor.getSavedState() {
                await viewModel.restoreState(savedState)
                monitor.clearSavedState()
            } else {
            }
        }

    }

    private func setupScheduleManager() {
        // When a schedule triggers, apply the mode
        scheduleManager.onApplyMode = { [weak deviceViewModel, weak settingsService] modeId in
            guard let viewModel = deviceViewModel,
                  let settings = settingsService,
                  settings.schedulesEnabled,
                  let mode = settings.getMode(by: modeId) else { return }

            await viewModel.applyMode(mode)
        }

    }

    private func performStartupTasks() async {
        // Auto-connect to last device
        if settingsService.autoConnect {
            await deviceViewModel.autoConnect(using: settingsService)
        }

        // If not connected and auto-discovery is enabled, try to discover
        if !deviceViewModel.isConnected && settingsService.autoDiscovery {
            let devices = await deviceViewModel.backgroundDiscovery()

            if let firstDevice = devices.first {
                // Cache discovered devices
                for device in devices {
                    settingsService.cacheDevice(device)
                }

                // Auto-connect to first discovered device
                if settingsService.autoConnect {
                    await deviceViewModel.connect(to: firstDevice)
                    if deviceViewModel.isConnected {
                        settingsService.selectedDeviceId = firstDevice.id
                    }
                }
            }
        }
    }
}
