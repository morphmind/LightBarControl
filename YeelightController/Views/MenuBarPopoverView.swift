import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject var viewModel: DeviceViewModel
    @EnvironmentObject var settings: SettingsService
    @EnvironmentObject var scheduleManager: ScheduleManager

    @State private var currentView: AppView = .main
    @State private var showAddPreset = false
    @State private var newPresetName = ""

    enum AppView {
        case main
        case discovery
        case settings
        case allModes
    }

    var body: some View {
        Group {
            switch currentView {
            case .main:
                mainView
            case .discovery:
                DiscoveryView(isPresented: Binding(
                    get: { currentView == .discovery },
                    set: { if !$0 { currentView = .main } }
                ))
            case .settings:
                SettingsView(isPresented: Binding(
                    get: { currentView == .settings },
                    set: { if !$0 { currentView = .main } }
                ))
            case .allModes:
                AllModesView(isPresented: Binding(
                    get: { currentView == .allModes },
                    set: { if !$0 { currentView = .main } }
                ))
            }
        }
        .background(GlassBackground())
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    // MARK: - Main View

    private var mainView: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            if viewModel.isConnected {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Device Status Card
                        deviceStatusCard
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        // Quick Modes Section
                        quickModesSection
                            .padding(.horizontal, 16)

                        // Main Light Control
                        mainLightCard
                            .padding(.horizontal, 16)

                        // Ambient Light Control
                        ambientLightCard
                            .padding(.horizontal, 16)

                        // Timer Section (collapsible)
                        timerSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
            } else {
                disconnectedView
            }

            // Footer
            footerView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 10) {
            // App Icon with glass effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.8),
                                Color.accentColor.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 2)

                Image(systemName: "lightbulb.led.wide.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("LightBar Control")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            // Settings button
            GlassIconButton(icon: "gearshape.fill") {
                currentView = .settings
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Device Status Card

    private var isAnyLightOn: Bool {
        (viewModel.state?.mainPower ?? false) || (viewModel.state?.bgPower ?? false)
    }

    private var deviceStatusCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                // Animated status indicator
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    isAnyLightOn ? Color.green.opacity(0.6) : Color.gray.opacity(0.2),
                                    isAnyLightOn ? Color.green.opacity(0.1) : Color.gray.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    isAnyLightOn ? Color.green.opacity(0.4) : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: "lightbulb.led.wide.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isAnyLightOn ? .white : .gray)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.device?.name ?? "Yeelight")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)

                        Text("Connected")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text(viewModel.device?.ipAddress ?? "")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 8)

                // Master Power button - controls BOTH lights
                GlassPowerButton(
                    isOn: isAnyLightOn,
                    size: 42
                ) {
                    Task {
                        let turnOn = !isAnyLightOn
                        // Update UI immediately
                        viewModel.state?.mainPower = turnOn
                        viewModel.state?.bgPower = turnOn
                        // Send commands
                        await viewModel.setMainPower(turnOn)
                        await viewModel.setBgPower(turnOn)
                    }
                }
            }
        }
    }

    // MARK: - Quick Modes Section

    private var quickModesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("QUICK MODES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()

                Button(action: { currentView = .allModes }) {
                    HStack(spacing: 3) {
                        Text("All")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            // 4-mode horizontal scroll
            HStack(spacing: 10) {
                ForEach(settings.getFavoriteModes()) { mode in
                    GlassModeCard(mode: mode) {
                        Task { await viewModel.applyMode(mode) }
                    }
                }
            }
        }
    }

    // MARK: - Main Light Card

    private var mainLightCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 28, height: 28)
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }

                        Text("Main Light")
                            .font(.system(size: 13, weight: .semibold))
                    }

                    Spacer()

                    GlassToggle(
                        isOn: Binding(
                            get: { viewModel.state?.mainPower ?? false },
                            set: { newValue in
                                viewModel.state?.mainPower = newValue
                                Task { await viewModel.setMainPower(newValue) }
                            }
                        ),
                        tintColor: .orange
                    )
                }

                // Brightness
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "sun.min")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        GlassSlider(
                            value: Binding(
                                get: { Double(viewModel.state?.mainBrightness ?? 50) },
                                set: { viewModel.updateMainBrightness(Int($0)) }
                            ),
                            range: 1...100,
                            tintColor: .orange
                        )

                        Image(systemName: "sun.max")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Text("\(viewModel.state?.mainBrightness ?? 50)%")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }

                    // Color Temperature
                    HStack(spacing: 10) {
                        Text("2700K")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)

                        GlassTemperatureSlider(
                            value: Binding(
                                get: { Double(viewModel.state?.colorTemperature ?? 4500) },
                                set: { viewModel.updateColorTemperature(Int($0)) }
                            )
                        )

                        Text("6500K")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .opacity(viewModel.state?.mainPower == true ? 1.0 : 0.4)
                .disabled(viewModel.state?.mainPower != true)
            }
        }
    }

    // MARK: - Ambient Light Card

    private var ambientLightCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 28, height: 28)
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(.purple)
                        }

                        Text("Ambient Light")
                            .font(.system(size: 13, weight: .semibold))
                    }

                    Spacer()

                    GlassToggle(
                        isOn: Binding(
                            get: { viewModel.state?.bgPower ?? false },
                            set: { newValue in
                                viewModel.state?.bgPower = newValue
                                Task { await viewModel.setBgPower(newValue) }
                            }
                        ),
                        tintColor: .purple
                    )
                }

                VStack(spacing: 12) {
                    // Brightness
                    HStack(spacing: 10) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        GlassSlider(
                            value: Binding(
                                get: { Double(viewModel.state?.bgBrightness ?? 50) },
                                set: { viewModel.updateBgBrightness(Int($0)) }
                            ),
                            range: 1...100,
                            tintColor: .purple
                        )

                        Text("\(viewModel.state?.bgBrightness ?? 50)%")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }

                    // Color Palette
                    GlassColorPalette(
                        onSelectRGB: { rgb in
                            viewModel.setBgColorDirect(rgb)
                        }
                    )
                }
                .opacity(viewModel.state?.bgPower == true ? 1.0 : 0.4)
                .disabled(viewModel.state?.bgPower != true)
            }
        }
    }

    // MARK: - Timer Section

    @State private var showTimer = false

    private var timerSection: some View {
        VStack(spacing: 0) {
            GlassCard {
                Button(action: { withAnimation(.spring(response: 0.3)) { showTimer.toggle() } }) {
                    HStack {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "timer")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }

                            Text("Timer")
                                .font(.system(size: 13, weight: .semibold))
                        }

                        if viewModel.isTimerActive {
                            Text("\(viewModel.timerMinutes) min")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                        }

                        Spacer()

                        Image(systemName: showTimer ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            if showTimer {
                TimerView()
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Disconnected View

    private var disconnectedView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.05)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )

                Image(systemName: "lightbulb.slash")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                Text("Device Not Connected")
                    .font(.system(size: 16, weight: .semibold))

                Text("Search for your Yeelight\ndevice to get started")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { currentView = .discovery }) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Search Devices")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)

            // LAN Control tip
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 12))

                Text("Enable LAN Control in Yeelight app")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )

            Spacer()
        }
        .padding()
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            if viewModel.isConnected {
                HStack(spacing: 5) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)

                    Text(viewModel.device?.name ?? "Connected")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else if viewModel.isConnecting {
                HStack(spacing: 5) {
                    ProgressView()
                        .scaleEffect(0.5)

                    Text("Connecting...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 5) {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)

                    Text("Not Connected")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .font(.system(size: 11))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Glass Background

struct GlassBackground: View {
    var body: some View {
        ZStack {
            // Base dark background
            Color(NSColor.windowBackgroundColor)

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.03),
                    Color.clear,
                    Color.black.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))

                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
    }
}

// MARK: - Glass Icon Button

struct GlassIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 32, height: 32)

                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Power Button

struct GlassPowerButton: View {
    let isOn: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                isOn ? Color.green.opacity(0.3) : Color.clear,
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size + 8, height: size + 8)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isOn
                                ? [Color.green.opacity(0.3), Color.green.opacity(0.15)]
                                : [Color.secondary.opacity(0.15), Color.secondary.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                // Border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isOn
                                ? [Color.green.opacity(0.6), Color.green.opacity(0.2)]
                                : [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: size, height: size)

                // Icon
                Image(systemName: "power")
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundColor(isOn ? .green : .secondary)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
    }
}

// MARK: - Glass Toggle

struct GlassToggle: View {
    @Binding var isOn: Bool
    let tintColor: Color

    var body: some View {
        Button(action: { isOn.toggle() }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                // Track
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isOn
                                ? [tintColor.opacity(0.4), tintColor.opacity(0.2)]
                                : [Color.secondary.opacity(0.2), Color.secondary.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 48, height: 28)
                    .overlay(
                        Capsule()
                            .stroke(
                                isOn ? tintColor.opacity(0.4) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )

                // Thumb
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 22, height: 22)
                        .shadow(color: isOn ? tintColor.opacity(0.3) : Color.black.opacity(0.15), radius: 4, y: 2)

                    if isOn {
                        Circle()
                            .fill(tintColor)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(3)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Mode Card

struct GlassModeCard: View {
    let mode: LightMode
    let onTap: () -> Void

    @State private var isPressed = false

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
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [modeColor.opacity(0.4), modeColor.opacity(0.1)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 48, height: 48)

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [modeColor.opacity(0.8), modeColor.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                    Image(systemName: mode.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }

                Text(mode.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(width: 68)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(isPressed ? 0.3 : 0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Glass Slider

struct GlassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tintColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)

                // Track fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tintColor.opacity(0.5), tintColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width), height: 8)

                // Thumb
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(tintColor.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: tintColor.opacity(0.3), radius: 4, y: 2)
                    .offset(x: max(0, CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * (geometry.size.width - 18)))
            }
            .frame(height: 18)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let progress = gesture.location.x / geometry.size.width
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(max(0, min(1, progress)))
                        value = newValue
                    }
            )
        }
        .frame(height: 18)
    }
}

// MARK: - Glass Temperature Slider

struct GlassTemperatureSlider: View {
    @Binding var value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Gradient track
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.4),  // Warm
                                Color.white,
                                Color(red: 0.7, green: 0.85, blue: 1.0)  // Cool
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                // Thumb
                let progress = (value - 2700) / 3800
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .offset(x: CGFloat(progress) * (geometry.size.width - 18))
            }
            .frame(height: 18)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let progress = gesture.location.x / geometry.size.width
                        let temp = 2700 + 3800 * Double(max(0, min(1, progress)))
                        value = temp
                    }
            )
        }
        .frame(height: 18)
    }
}

// MARK: - Glass Color Palette

struct GlassColorPalette: View {
    var onSelectRGB: (Int) -> Void

    private let presetColors: [(Color, Int)] = [
        (Color(red: 1.0, green: 0.3, blue: 0.3), 0xFF4D4D),
        (Color(red: 1.0, green: 0.6, blue: 0.2), 0xFF9933),
        (Color(red: 1.0, green: 0.9, blue: 0.3), 0xFFE64D),
        (Color(red: 0.4, green: 0.9, blue: 0.4), 0x66E666),
        (Color(red: 0.3, green: 0.7, blue: 1.0), 0x4DB3FF),
        (Color(red: 0.7, green: 0.4, blue: 0.9), 0xB366E6),
        (Color(red: 1.0, green: 0.5, blue: 0.7), 0xFF80B3),
        (Color.white, 0xFFFFFF)
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(presetColors, id: \.1) { color, rgb in
                Button(action: { onSelectRGB(rgb) }) {
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                            .shadow(color: color.opacity(0.5), radius: 4, y: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
