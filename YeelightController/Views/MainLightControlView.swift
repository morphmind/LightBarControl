import SwiftUI

struct MainLightControlView: View {
    @EnvironmentObject var viewModel: DeviceViewModel

    @State private var brightness: Double = 80
    @State private var colorTemperature: Double = 4500

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with power toggle
            HStack {
                Label("Ana Isik", systemImage: "lightbulb.fill")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.state?.mainPower ?? false },
                    set: { _ in
                        Task {
                            await viewModel.toggleMainPower()
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
                            viewModel.updateMainBrightness(Int(brightness))
                        }
                    }

                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .disabled(!(viewModel.state?.mainPower ?? false))
            .opacity((viewModel.state?.mainPower ?? false) ? 1 : 0.5)

            // Color Temperature Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Renk Sicakligi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(colorTemperature))K")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Gradient background
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.4),  // Warm
                                    Color.white,                              // Neutral
                                    Color(red: 0.7, green: 0.85, blue: 1.0)  // Cool
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(height: 6)
                            .cornerRadius(3)

                            // Custom slider
                            Slider(value: $colorTemperature, in: 2700...6500, step: 100) { editing in
                                if !editing {
                                    viewModel.updateColorTemperature(Int(colorTemperature))
                                }
                            }
                            .accentColor(.clear)
                        }
                    }
                    .frame(height: 20)

                    Circle()
                        .fill(Color(red: 0.7, green: 0.85, blue: 1.0))
                        .frame(width: 12, height: 12)
                }

                HStack {
                    Text("Sicak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Soguk")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(!(viewModel.state?.mainPower ?? false))
            .opacity((viewModel.state?.mainPower ?? false) ? 1 : 0.5)
        }
        .onAppear {
            updateFromState()
        }
        .onChange(of: viewModel.state) { _ in
            updateFromState()
        }
    }

    private func updateFromState() {
        if let state = viewModel.state {
            brightness = Double(state.mainBrightness)
            colorTemperature = Double(state.colorTemperature)
        }
    }
}
