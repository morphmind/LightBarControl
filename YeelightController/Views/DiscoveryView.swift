import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var viewModel: DeviceViewModel
    @EnvironmentObject var settings: SettingsService

    @Binding var isPresented: Bool

    @State private var manualIP = ""
    @State private var showManualEntry = false
    @State private var showLanHelp = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Text("Cihaz Bul")
                    .font(.headline)

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Kapat")
            }

            Divider()

            // LAN Control Help Card
            lanControlHelpCard

            // Scan button
            Button(action: {
                Task {
                    await viewModel.discoverDevices()
                }
            }) {
                HStack {
                    if viewModel.isDiscovering {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(viewModel.isDiscovering ? "Araniyor..." : "Cihaz Ara")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isDiscovering)

            // Discovered devices list
            if !viewModel.discoveredDevices.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Bulunan Cihazlar")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(viewModel.discoveredDevices.count) cihaz")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ForEach(viewModel.discoveredDevices) { device in
                        deviceRow(device)
                    }
                }
            }

            // Known devices
            if !settings.knownDevices.isEmpty && viewModel.discoveredDevices.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Onceden Baglanan Cihazlar")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }

                    ForEach(settings.knownDevices) { device in
                        deviceRow(device)
                    }
                }
            }

            Divider()

            // Manual entry
            DisclosureGroup("Manuel IP Girisi", isExpanded: $showManualEntry) {
                HStack {
                    TextField("IP Adresi (ornek: 192.168.1.100)", text: $manualIP)
                        .textFieldStyle(.roundedBorder)

                    Button("Ekle") {
                        Task {
                            if await viewModel.addManualDevice(ip: manualIP) {
                                manualIP = ""
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(manualIP.isEmpty)
                }
            }
            .font(.caption)

            Spacer()
        }
        .padding()
        .frame(width: 320, height: 600)
    }

    // MARK: - LAN Control Help Card

    private var lanControlHelpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { withAnimation { showLanHelp.toggle() } }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("LAN Control Acik Olmali!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: showLanHelp ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            if showLanHelp {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Yeelight cihazinizi bulabilmem icin LAN Control ayarinin acik olmasi gerekiyor.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    // Step by step guide
                    VStack(alignment: .leading, spacing: 8) {
                        stepRow(number: 1, text: "Telefonunuzda Yeelight veya Mi Home uygulamasini acin")
                        stepRow(number: 2, text: "Kontrol etmek istediginiz cihazi secin")
                        stepRow(number: 3, text: "Sag ustteki ayarlar (⚙️) ikonuna tiklayin")
                        stepRow(number: 4, text: "\"LAN Control\" secenegini bulun")
                        stepRow(number: 5, text: "Anahtari ACIK konuma getirin")
                    }

                    Divider()

                    // Additional info
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)

                        Text("Ipucu: Cihaz ve Mac ayni WiFi aginda olmali!")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.orange))

            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Device Row

    private func deviceRow(_ device: YeelightDevice) -> some View {
        Button(action: {
            Task {
                await viewModel.connect(to: device)
                if viewModel.isConnected {
                    settings.selectedDeviceId = device.id
                    settings.cacheDevice(device)
                    isPresented = false
                }
            }
        }) {
            HStack(spacing: 12) {
                // Device icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.8), Color.accentColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: "lightbulb.led.wide.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .font(.system(size: 9))
                        Text(device.ipAddress)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.isConnecting && viewModel.device?.id == device.id {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
