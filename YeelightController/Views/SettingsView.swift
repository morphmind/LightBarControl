import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: DeviceViewModel
    @EnvironmentObject var settings: SettingsService
    @EnvironmentObject var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    var isPresented: Binding<Bool>?

    @State private var showResetConfirmation = false
    @State private var showScheduleEditor = false
    @State private var editingSchedule: LightSchedule?

    init(isPresented: Binding<Bool>? = nil) {
        self.isPresented = isPresented
    }

    private func closeSheet() {
        if let isPresented = isPresented {
            isPresented.wrappedValue = false
        } else {
            dismiss()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.accentColor)

                Text("Settings")
                    .font(.headline)

                Spacer()

                Button(action: closeSheet) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Connection Section
                    SettingsSection(title: "Connection", icon: "wifi") {
                        SettingsToggle(
                            title: "Auto Connect",
                            subtitle: "Connect to last device on startup",
                            isOn: $settings.autoConnect
                        )

                        SettingsToggle(
                            title: "Auto Discovery",
                            subtitle: "Scan for devices on startup",
                            isOn: $settings.autoDiscovery
                        )

                        if let device = viewModel.device {
                            Divider()
                                .padding(.vertical, 4)

                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "lightbulb.led.wide.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("\(device.ipAddress) • \(device.model)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if viewModel.isConnected {
                                    Button("Disconnect") {
                                        Task { await viewModel.disconnect() }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }

                    // Automation Section
                    SettingsSection(title: "Automation", icon: "bolt.fill") {
                        SettingsToggle(
                            title: "Turn Off on Sleep",
                            subtitle: "Turn off lights when display sleeps",
                            isOn: $settings.turnOffOnSleep
                        )

                        SettingsToggle(
                            title: "Restore on Wake",
                            subtitle: "Restore previous state when display wakes",
                            isOn: $settings.restoreOnWake
                        )

                        Divider()
                            .padding(.vertical, 4)

                        SettingsToggle(
                            title: "Enable Schedules",
                            subtitle: "Time-based automatic mode changes",
                            isOn: $settings.schedulesEnabled
                        )
                    }

                    // Schedules Section
                    SettingsSection(title: "Schedules", icon: "calendar.badge.clock") {
                        if scheduleManager.schedules.isEmpty {
                            HStack {
                                Spacer()
                                Text("No schedules yet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(scheduleManager.schedules) { schedule in
                                ScheduleRow(
                                    schedule: schedule,
                                    modeName: settings.getMode(by: schedule.modeId)?.name ?? "Unknown",
                                    onToggle: { scheduleManager.toggleSchedule(schedule.id) },
                                    onEdit: {
                                        editingSchedule = schedule
                                        showScheduleEditor = true
                                    }
                                )

                                if schedule.id != scheduleManager.schedules.last?.id {
                                    Divider()
                                }
                            }
                        }

                        Button(action: {
                            editingSchedule = nil
                            showScheduleEditor = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                Text("Add New Schedule")
                                    .font(.subheadline)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }

                    // Modes Section
                    SettingsSection(title: "Modes", icon: "square.grid.2x2.fill") {
                        VStack(spacing: 8) {
                            ForEach(settings.modes) { mode in
                                ModeInfoRow(mode: mode, isFavorite: settings.favoriteModeIds.contains(mode.id)) {
                                    settings.toggleFavorite(mode.id)
                                }
                            }
                        }

                        Divider()
                            .padding(.vertical, 4)

                        Button(action: {
                            settings.resetModesToDefaults()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.orange)
                                Text("Reset to Default Modes")
                                    .font(.subheadline)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Startup Section
                    SettingsSection(title: "System", icon: "desktopcomputer") {
                        SettingsToggle(
                            title: "Launch at Login",
                            subtitle: "Start automatically on macOS login",
                            isOn: Binding(
                                get: { settings.launchAtLogin },
                                set: { settings.launchAtLogin = $0 }
                            )
                        )
                    }

                    // About Section
                    SettingsSection(title: "About", icon: "info.circle") {
                        HStack {
                            Text("Version")
                                .font(.subheadline)
                            Spacer()
                            Text("1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Developer Info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Developer")
                                    .font(.subheadline)
                                Spacer()
                                Text("Kaan YILDIZKAN")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Link(destination: URL(string: "https://yildizkan.com")!) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.accentColor)
                                    Text("yildizkan.com")
                                        .font(.subheadline)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Buy Me a Coffee
                        Link(destination: URL(string: "https://buymeacoffee.com/morphmind")!) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 1.0, green: 0.87, blue: 0.0), Color(red: 1.0, green: 0.72, blue: 0.0)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 28, height: 28)

                                    Text("☕")
                                        .font(.system(size: 14))
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Buy Me a Coffee")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Support development")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.pink)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 1.0, green: 0.87, blue: 0.0).opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.vertical, 4)

                        Link(destination: URL(string: "https://www.yeelight.com/en_US/developer")!) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.accentColor)
                                Text("Yeelight Developer")
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.vertical, 4)

                        Button(action: { showResetConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Reset All Settings")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .frame(width: isPresented != nil ? 320 : 450, height: isPresented != nil ? 600 : 550)
        .background(Color(NSColor.windowBackgroundColor))
        .confirmationDialog(
            "Reset All Settings",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
                scheduleManager.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All settings, modes and schedules will be deleted. This cannot be undone.")
        }
        .sheet(isPresented: $showScheduleEditor) {
            ScheduleEditorView(
                schedule: editingSchedule,
                modes: settings.modes,
                onSave: { schedule in
                    if editingSchedule != nil {
                        scheduleManager.updateSchedule(schedule)
                    } else {
                        scheduleManager.addSchedule(schedule)
                    }
                    showScheduleEditor = false
                },
                onCancel: { showScheduleEditor = false }
            )
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content

    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.accentColor)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .scaleEffect(0.8)
        }
    }
}

// MARK: - Schedule Row

struct ScheduleRow: View {
    let schedule: LightSchedule
    let modeName: String
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.formattedTime)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(modeName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Days indicator
            HStack(spacing: 2) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Text(day.shortName)
                        .font(.system(size: 8))
                        .foregroundColor(schedule.days.contains(day) ? .accentColor : .secondary.opacity(0.5))
                }
            }

            // Toggle
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .scaleEffect(0.7)

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Schedule Editor View

struct ScheduleEditorView: View {
    let schedule: LightSchedule?
    let modes: [LightMode]
    let onSave: (LightSchedule) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var startHour: Int = 8
    @State private var startMinute: Int = 0
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    @State private var selectedModeId: UUID?

    init(schedule: LightSchedule?, modes: [LightMode], onSave: @escaping (LightSchedule) -> Void, onCancel: @escaping () -> Void) {
        self.schedule = schedule
        self.modes = modes
        self.onSave = onSave
        self.onCancel = onCancel

        if let schedule = schedule {
            _name = State(initialValue: schedule.name)
            _startHour = State(initialValue: schedule.startHour)
            _startMinute = State(initialValue: schedule.startMinute)
            _selectedDays = State(initialValue: schedule.days)
            _selectedModeId = State(initialValue: schedule.modeId)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                Spacer()

                Text(schedule == nil ? "New Schedule" : "Edit Schedule")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    let newSchedule = LightSchedule(
                        id: schedule?.id ?? UUID(),
                        name: name.isEmpty ? "Schedule" : name,
                        startHour: startHour,
                        startMinute: startMinute,
                        days: selectedDays,
                        modeId: selectedModeId ?? modes.first?.id ?? UUID(),
                        isEnabled: schedule?.isEnabled ?? true
                    )
                    onSave(newSchedule)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(selectedModeId == nil)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Schedule Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Time")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Picker("", selection: $startHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 70)

                            Text(":")
                                .font(.title2)

                            Picker("", selection: $startMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 70)
                        }
                    }

                    // Days
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Days")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(Weekday.allCases, id: \.self) { day in
                                DayButton(
                                    day: day,
                                    isSelected: selectedDays.contains(day),
                                    onTap: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(modes) { mode in
                                ModeSelectButton(
                                    mode: mode,
                                    isSelected: selectedModeId == mode.id,
                                    onTap: { selectedModeId = mode.id }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 300, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if selectedModeId == nil {
                selectedModeId = modes.first?.id
            }
        }
    }
}

// MARK: - Day Button

struct DayButton: View {
    let day: Weekday
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(day.shortName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Select Button

struct ModeSelectButton: View {
    let mode: LightMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: mode.icon)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .white : .primary)
                }

                Text(mode.name)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Info Row

struct ModeInfoRow: View {
    let mode: LightMode
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    @State private var showInfo = false

    private var modeColor: Color {
        switch mode.icon {
        case "briefcase.fill": return .blue
        case "film.fill": return .indigo
        case "moon.fill": return .purple
        case "bed.double.fill": return .pink
        case "gamecontroller.fill": return .green
        case "book.fill": return .orange
        case "person.2.fill": return .cyan
        case "tv.fill": return .teal
        case "leaf.fill": return .mint
        default: return .accentColor
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Mode icon
                ZStack {
                    Circle()
                        .fill(modeColor.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: mode.icon)
                        .font(.system(size: 13))
                        .foregroundColor(modeColor)
                }

                // Mode name
                Text(mode.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                // Favorite star
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundColor(isFavorite ? .yellow : .secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help(isFavorite ? "Remove from favorites" : "Add to favorites")

                // Info button
                Button(action: { withAnimation(.spring(response: 0.3)) { showInfo.toggle() } }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(showInfo ? .accentColor : .secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)

            // Expanded info
            if showInfo {
                VStack(alignment: .leading, spacing: 8) {
                    if !mode.description.isEmpty {
                        Text(mode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 16) {
                        // Main light info
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Main")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(mode.mainPower ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)

                                Text(mode.mainPower ? "\(mode.mainBrightness)% • \(mode.colorTemperature)K" : "Off")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Ambient light info
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ambient")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(mode.bgPower ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)

                                if mode.bgPower {
                                    HStack(spacing: 4) {
                                        Text("\(mode.bgBrightness)%")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)

                                        Circle()
                                            .fill(mode.bgColor)
                                            .frame(width: 10, height: 10)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                } else {
                                    Text("Off")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 42)
                .padding(.bottom, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(showInfo ? Color.secondary.opacity(0.05) : Color.clear)
        )
    }
}
