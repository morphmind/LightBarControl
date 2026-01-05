import SwiftUI

struct QuickModesView: View {
    @EnvironmentObject var viewModel: DeviceViewModel
    @EnvironmentObject var settings: SettingsService

    @State private var activeModeId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("Hizli Modlar")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                // Show all modes button
                Button(action: {}) {
                    Text("Tumu")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            // 2x2 Grid of favorite modes
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(settings.getFavoriteModes()) { mode in
                    ModeButton(
                        mode: mode,
                        isActive: activeModeId == mode.id,
                        action: {
                            applyMode(mode)
                        }
                    )
                }
            }
        }
    }

    private func applyMode(_ mode: LightMode) {
        activeModeId = mode.id

        Task {
            await viewModel.applyMode(mode)

            // Reset active state after a delay
            try? await Task.sleep(nanoseconds: 500_000_000)
            if activeModeId == mode.id {
                activeModeId = nil
            }
        }
    }
}

// MARK: - Mode Button

struct ModeButton: View {
    let mode: LightMode
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: mode.icon)
                        .font(.system(size: 16))
                        .foregroundColor(isActive ? .white : .primary)
                }

                // Name
                Text(mode.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All Modes Grid View

struct AllModesView: View {
    @EnvironmentObject var viewModel: DeviceViewModel
    @EnvironmentObject var settings: SettingsService
    @Binding var isPresented: Bool

    @State private var activeModeId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { isPresented = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Geri")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Tum Modlar")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                // Placeholder for alignment
                Text("Geri")
                    .font(.system(size: 13))
                    .opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Modes grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(settings.modes) { mode in
                        EnhancedModeCard(
                            mode: mode,
                            isActive: activeModeId == mode.id,
                            isFavorite: settings.favoriteModeIds.contains(mode.id),
                            onTap: {
                                applyMode(mode)
                            },
                            onFavoriteToggle: {
                                settings.toggleFavorite(mode.id)
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 320, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func applyMode(_ mode: LightMode) {
        activeModeId = mode.id

        Task {
            await viewModel.applyMode(mode)

            try? await Task.sleep(nanoseconds: 500_000_000)
            if activeModeId == mode.id {
                activeModeId = nil
            }
        }
    }
}

// MARK: - Enhanced Mode Card

struct EnhancedModeCard: View {
    let mode: LightMode
    let isActive: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void

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
        case "rectangle.inset.filled.and.person.filled": return .teal
        case "leaf.fill": return .mint
        default: return .accentColor
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon with favorite indicator
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        modeColor.opacity(isActive ? 1.0 : 0.7),
                                        modeColor.opacity(isActive ? 0.8 : 0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: modeColor.opacity(isActive ? 0.5 : 0.2), radius: isActive ? 6 : 3, y: 2)

                        Image(systemName: mode.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    // Favorite star
                    if isFavorite {
                        ZStack {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 16, height: 16)

                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                        .offset(x: 4, y: -4)
                    }
                }

                // Name
                Text(mode.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Info badges
                HStack(spacing: 4) {
                    Text("\(mode.mainBrightness)%")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 2, height: 2)

                    Text("\(mode.colorTemperature)K")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: isActive ? modeColor.opacity(0.3) : .clear, radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? modeColor.opacity(0.5) : Color.secondary.opacity(0.1), lineWidth: isActive ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
        .contextMenu {
            Button(action: onFavoriteToggle) {
                Label(
                    isFavorite ? "Favorilerden Cikar" : "Favorilere Ekle",
                    systemImage: isFavorite ? "star.slash" : "star"
                )
            }
        }
    }
}

// MARK: - Mode Card (Legacy)

struct ModeCard: View {
    let mode: LightMode
    let isActive: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon with favorite star
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        isActive ? Color.accentColor : Color.secondary.opacity(0.2),
                                        isActive ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: mode.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isActive ? .white : .primary)
                    }

                    // Favorite indicator
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                            .offset(x: 4, y: -4)
                    }
                }

                // Name
                Text(mode.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Brief info
                HStack(spacing: 4) {
                    Text("\(mode.mainBrightness)%")
                        .font(.system(size: 9))

                    Text("•")
                        .font(.system(size: 9))

                    Text("\(mode.colorTemperature)K")
                        .font(.system(size: 9))
                }
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.accentColor : Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onFavoriteToggle) {
                Label(
                    isFavorite ? "Favorilerden Cikar" : "Favorilere Ekle",
                    systemImage: isFavorite ? "star.slash" : "star"
                )
            }
        }
    }
}
