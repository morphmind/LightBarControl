import Foundation

@MainActor
class ScheduleManager: ObservableObject {
    @Published var schedules: [LightSchedule] = []
    @Published var activeSchedule: LightSchedule?

    private var checkTimer: DispatchSourceTimer?
    private let schedulesKey = "lightSchedules"

    // Callback for applying modes
    var onApplyMode: ((UUID) async -> Void)?

    init() {
        loadSchedules()
        startScheduleChecker()
    }

    // MARK: - Persistence

    private func loadSchedules() {
        if let data = UserDefaults.standard.data(forKey: schedulesKey),
           let saved = try? JSONDecoder().decode([LightSchedule].self, from: data) {
            schedules = saved
        } else {
            // First run - load defaults (disabled)
            schedules = LightSchedule.defaults
            saveSchedules()
        }
        updateActiveSchedule()
    }

    private func saveSchedules() {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: schedulesKey)
        }
    }

    // MARK: - CRUD Operations

    func addSchedule(_ schedule: LightSchedule) {
        schedules.append(schedule)
        saveSchedules()
    }

    func updateSchedule(_ schedule: LightSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            saveSchedules()
            updateActiveSchedule()
        }
    }

    func deleteSchedule(_ id: UUID) {
        schedules.removeAll { $0.id == id }
        saveSchedules()
        updateActiveSchedule()
    }

    func toggleSchedule(_ id: UUID) {
        if let index = schedules.firstIndex(where: { $0.id == id }) {
            schedules[index].isEnabled.toggle()
            saveSchedules()
            updateActiveSchedule()
        }
    }

    // MARK: - Schedule Checking

    private func startScheduleChecker() {
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now(), repeating: 60)  // Check every minute

        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.checkSchedules()
            }
        }

        timer.resume()
        checkTimer = timer
    }

    private func checkSchedules() {
        let previousActive = activeSchedule
        updateActiveSchedule()

        // If active schedule changed, apply the new mode
        if activeSchedule?.id != previousActive?.id {
            if let schedule = activeSchedule {
                Task {
                    await onApplyMode?(schedule.modeId)
                }
            }
        }

        // Also check for exact trigger times
        for schedule in schedules where schedule.shouldTriggerNow() {
            Task {
                await onApplyMode?(schedule.modeId)
            }
        }
    }

    private func updateActiveSchedule() {
        activeSchedule = schedules.first { $0.isActiveNow() }
    }

    // MARK: - Helpers

    func getSchedule(by id: UUID) -> LightSchedule? {
        schedules.first { $0.id == id }
    }

    func getEnabledSchedules() -> [LightSchedule] {
        schedules.filter { $0.isEnabled }
    }

    func getNextSchedule() -> (schedule: LightSchedule, date: Date)? {
        let upcoming = schedules.compactMap { schedule -> (LightSchedule, Date)? in
            guard let nextDate = schedule.nextTriggerDate() else { return nil }
            return (schedule, nextDate)
        }
        return upcoming.min { $0.1 < $1.1 }
    }

    func resetToDefaults() {
        schedules = LightSchedule.defaults
        saveSchedules()
        updateActiveSchedule()
    }
}
