import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: DeviceViewModel

    @State private var customMinutes: Int = 30
    @State private var showCustomTimer = false

    private let presetMinutes = [15, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Zamanlayici", systemImage: "timer")
                    .font(.headline)

                Spacer()

                if viewModel.isTimerActive {
                    Button(action: {
                        Task {
                            await viewModel.cancelTimer()
                        }
                    }) {
                        Text("Iptal")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Timer status
            if viewModel.isTimerActive {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.timerMinutes) dakika sonra kapanacak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Preset buttons
            HStack(spacing: 8) {
                ForEach(presetMinutes, id: \.self) { minutes in
                    timerButton(minutes: minutes)
                }

                Button(action: {
                    showCustomTimer.toggle()
                }) {
                    Text("Ozel")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            // Custom timer
            if showCustomTimer {
                HStack {
                    Stepper(value: $customMinutes, in: 1...180, step: 5) {
                        Text("\(customMinutes) dk")
                            .monospacedDigit()
                    }

                    Button("Ayarla") {
                        Task {
                            await viewModel.setTimer(minutes: customMinutes)
                            showCustomTimer = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 4)
            }
        }
    }

    private func timerButton(minutes: Int) -> some View {
        Button(action: {
            Task {
                await viewModel.setTimer(minutes: minutes)
            }
        }) {
            Text("\(minutes)dk")
                .font(.caption)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(viewModel.timerMinutes == minutes && viewModel.isTimerActive ? .orange : nil)
    }
}
