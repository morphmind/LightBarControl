import SwiftUI

struct PresetListView: View {
    @EnvironmentObject var viewModel: DeviceViewModel
    @EnvironmentObject var settings: SettingsService

    @Binding var showAddPreset: Bool
    @State private var presetToDelete: LightPreset?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Presetler", systemImage: "bookmark.fill")
                    .font(.headline)

                Spacer()

                Button(action: {
                    showAddPreset = true
                }) {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .help("Yeni preset ekle")
            }

            // Preset grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(settings.presets) { preset in
                    presetButton(preset)
                }
            }
        }
        .confirmationDialog(
            "Preseti Sil",
            isPresented: Binding(
                get: { presetToDelete != nil },
                set: { if !$0 { presetToDelete = nil } }
            ),
            presenting: presetToDelete
        ) { preset in
            Button("Sil", role: .destructive) {
                settings.deletePreset(preset.id)
                presetToDelete = nil
            }
            Button("Iptal", role: .cancel) {
                presetToDelete = nil
            }
        } message: { preset in
            Text("'\(preset.name)' presetini silmek istediginizden emin misiniz?")
        }
    }

    private func presetButton(_ preset: LightPreset) -> some View {
        Button(action: {
            Task {
                await viewModel.applyPreset(preset)
            }
        }) {
            HStack {
                presetColorIndicator(preset)

                Text(preset.name)
                    .font(.caption)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: {
                Task {
                    await viewModel.applyPreset(preset)
                }
            }) {
                Label("Uygula", systemImage: "checkmark")
            }

            Divider()

            Button(role: .destructive, action: {
                presetToDelete = preset
            }) {
                Label("Sil", systemImage: "trash")
            }
        }
    }

    private func presetColorIndicator(_ preset: LightPreset) -> some View {
        ZStack {
            // Main light indicator
            Circle()
                .fill(colorForTemperature(preset.colorTemperature))
                .frame(width: 16, height: 16)
                .opacity(preset.mainPower ? 1 : 0.3)

            // Background light indicator
            if preset.bgPower {
                Circle()
                    .stroke(colorFromRGB(preset.bgRGB), lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
        }
    }

    private func colorForTemperature(_ kelvin: Int) -> Color {
        let t = Double(kelvin - 2700) / 3800.0 // 0 to 1
        return Color(
            red: 1.0 - t * 0.3,
            green: 0.85 + t * 0.15,
            blue: 0.6 + t * 0.4
        )
    }

    private func colorFromRGB(_ rgb: Int) -> Color {
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
}
