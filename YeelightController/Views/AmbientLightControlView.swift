import SwiftUI

struct AmbientLightControlView: View {
    @EnvironmentObject var viewModel: DeviceViewModel

    @State private var brightness: Double = 50
    @State private var selectedColor: Color = .orange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with power toggle
            HStack {
                Label("Arka Isik", systemImage: "circle.hexagongrid.fill")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.state?.bgPower ?? false },
                    set: { _ in
                        Task {
                            await viewModel.toggleBgPower()
                        }
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            // Brightness Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Parlaklik")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(brightness))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Image(systemName: "sun.min")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Slider(value: $brightness, in: 1...100, step: 1) { editing in
                        if !editing {
                            viewModel.updateBgBrightness(Int(brightness))
                        }
                    }

                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .disabled(!(viewModel.state?.bgPower ?? false))
            .opacity((viewModel.state?.bgPower ?? false) ? 1 : 0.5)

            // Color Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Renk")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .onChange(of: selectedColor) { newColor in
                            viewModel.updateBgColor(newColor)
                        }

                    Spacer()

                    // Quick color presets
                    quickColorButton(.red, name: "Kirmizi")
                    quickColorButton(.orange, name: "Turuncu")
                    quickColorButton(.yellow, name: "Sari")
                    quickColorButton(.green, name: "Yesil")
                    quickColorButton(.blue, name: "Mavi")
                    quickColorButton(.purple, name: "Mor")
                }
            }
            .disabled(!(viewModel.state?.bgPower ?? false))
            .opacity((viewModel.state?.bgPower ?? false) ? 1 : 0.5)
        }
        .onAppear {
            updateFromState()
        }
        .onChange(of: viewModel.state) { _ in
            updateFromState()
        }
    }

    private func quickColorButton(_ color: Color, name: String) -> some View {
        Button(action: {
            selectedColor = color
            viewModel.updateBgColor(color)
        }) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(name)
    }

    private func updateFromState() {
        if let state = viewModel.state {
            brightness = Double(state.bgBrightness)
            selectedColor = state.bgColor
        }
    }
}
