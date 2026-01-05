import Foundation

struct LightSchedule: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var startHour: Int  // 0-23
    var startMinute: Int  // 0-59
    var endHour: Int?  // Optional end time
    var endMinute: Int?
    var days: Set<Weekday>
    var modeId: UUID  // Reference to LightMode
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "clock.fill",
        startHour: Int,
        startMinute: Int = 0,
        endHour: Int? = nil,
        endMinute: Int? = nil,
        days: Set<Weekday> = Set(Weekday.allCases),
        modeId: UUID,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.days = days
        self.modeId = modeId
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var startTimeString: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }

    var formattedTime: String {
        startTimeString
    }

    var endTimeString: String? {
        guard let endHour = endHour, let endMinute = endMinute else { return nil }
        return String(format: "%02d:%02d", endHour, endMinute)
    }

    var daysString: String {
        if days.count == 7 {
            return "Her gun"
        } else if days == Set([.monday, .tuesday, .wednesday, .thursday, .friday]) {
            return "Hafta ici"
        } else if days == Set([.saturday, .sunday]) {
            return "Hafta sonu"
        } else {
            return days.sorted(by: { $0.rawValue < $1.rawValue })
                .map { $0.shortName }
                .joined(separator: ", ")
        }
    }

    // MARK: - Schedule Logic

    func shouldTriggerNow() -> Bool {
        guard isEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = Weekday.from(calendar.component(.weekday, from: now))

        guard days.contains(currentWeekday) else { return false }

        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        return currentHour == startHour && currentMinute == startMinute
    }

    func isActiveNow() -> Bool {
        guard isEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = Weekday.from(calendar.component(.weekday, from: now))

        guard days.contains(currentWeekday) else { return false }

        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute

        if let endHour = endHour, let endMinute = endMinute {
            let endMinutes = endHour * 60 + endMinute

            if endMinutes > startMinutes {
                // Same day schedule (e.g., 08:00 - 18:00)
                return currentMinutes >= startMinutes && currentMinutes < endMinutes
            } else {
                // Overnight schedule (e.g., 22:00 - 08:00)
                return currentMinutes >= startMinutes || currentMinutes < endMinutes
            }
        }

        // No end time - just check if past start time
        return currentMinutes >= startMinutes
    }

    func nextTriggerDate() -> Date? {
        guard isEnabled else { return nil }

        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = .current

        // Try today first
        for dayOffset in 0..<8 {
            guard let candidateDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            let weekday = Weekday.from(calendar.component(.weekday, from: candidateDate))
            guard days.contains(weekday) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: candidateDate)
            components.hour = startHour
            components.minute = startMinute
            components.second = 0

            guard let triggerDate = calendar.date(from: components) else { continue }

            if triggerDate > now {
                return triggerDate
            }
        }

        return nil
    }

    // MARK: - Default Schedules

    static let defaults: [LightSchedule] = [
        // Sabah - Calisma modu
        LightSchedule(
            id: UUID(uuidString: "10000001-0000-0000-0000-000000000001")!,
            name: "Sabah",
            icon: "sunrise.fill",
            startHour: 8,
            startMinute: 0,
            endHour: 18,
            endMinute: 0,
            days: Set([.monday, .tuesday, .wednesday, .thursday, .friday]),
            modeId: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,  // Calisma
            isEnabled: false
        ),
        // Aksam - Rahatlatici modu
        LightSchedule(
            id: UUID(uuidString: "10000002-0000-0000-0000-000000000002")!,
            name: "Aksam",
            icon: "sunset.fill",
            startHour: 18,
            startMinute: 0,
            endHour: 22,
            endMinute: 0,
            days: Set(Weekday.allCases),
            modeId: UUID(uuidString: "00000003-0000-0000-0000-000000000003")!,  // Rahatlatici
            isEnabled: false
        ),
        // Gece - Dinlenme modu
        LightSchedule(
            id: UUID(uuidString: "10000003-0000-0000-0000-000000000003")!,
            name: "Gece",
            icon: "moon.stars.fill",
            startHour: 22,
            startMinute: 0,
            endHour: 8,
            endMinute: 0,
            days: Set(Weekday.allCases),
            modeId: UUID(uuidString: "00000004-0000-0000-0000-000000000004")!,  // Dinlenme
            isEnabled: false
        )
    ]
}

// MARK: - Weekday

enum Weekday: Int, Codable, CaseIterable, Comparable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var name: String {
        switch self {
        case .sunday: return "Pazar"
        case .monday: return "Pazartesi"
        case .tuesday: return "Sali"
        case .wednesday: return "Carsamba"
        case .thursday: return "Persembe"
        case .friday: return "Cuma"
        case .saturday: return "Cumartesi"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Paz"
        case .monday: return "Pzt"
        case .tuesday: return "Sal"
        case .wednesday: return "Car"
        case .thursday: return "Per"
        case .friday: return "Cum"
        case .saturday: return "Cmt"
        }
    }

    var initial: String {
        switch self {
        case .sunday: return "P"
        case .monday: return "P"
        case .tuesday: return "S"
        case .wednesday: return "C"
        case .thursday: return "P"
        case .friday: return "C"
        case .saturday: return "C"
        }
    }

    static func from(_ calendarWeekday: Int) -> Weekday {
        Weekday(rawValue: calendarWeekday) ?? .sunday
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        // Monday first ordering
        let order: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else { return false }
        return lhsIndex < rhsIndex
    }
}
