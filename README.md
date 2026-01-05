<p align="center">
  <img src="assets/app-icon.png" alt="LightBar Control" width="128" height="128">
</p>

<h1 align="center">LightBar Control</h1>

<p align="center">
  <strong>The ultimate macOS menu bar app for controlling your Yeelight Monitor Light Bar</strong>
</p>

<p align="center">
  <a href="https://github.com/kaanyildizkan/LightBarControl/releases">
    <img src="https://img.shields.io/github/v/release/kaanyildizkan/LightBarControl?style=flat-square" alt="Release">
  </a>
  <a href="https://github.com/kaanyildizkan/LightBarControl/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/kaanyildizkan/LightBarControl?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift">
</p>

<p align="center">
  <a href="https://buymeacoffee.com/morphmind">
    <img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?style=flat-square&logo=buy-me-a-coffee" alt="Buy Me A Coffee">
  </a>
</p>

<p align="center">
  <img src="assets/screenshot-hero.png" alt="LightBar Control Screenshot" width="600">
</p>

---

## ✨ Features

### 🎛️ Quick Control from Menu Bar
- **One-click power toggle** - Turn your light bar on/off instantly
- **Lives in your menu bar** - Always accessible, never in the way
- **Beautiful glass-effect UI** - Modern, elegant interface designed for macOS

### 💡 Main Light Control
- **Brightness adjustment** - Smoothly adjust from 1% to 100%
- **Color temperature** - Set the perfect ambiance from warm (2700K) to cool (6500K)
- **Real-time preview** - See changes instantly as you adjust

### 🌈 Ambient Light Control
- **Full RGB color palette** - Choose any color for your ambient light
- **Brightness control** - Independent brightness for ambient light
- **Quick color presets** - Red, Orange, Yellow, Green, Blue, Purple, Pink, White

### 🎯 Smart Lighting Modes
9 preset modes for every situation:

| Mode | Icon | Description |
|------|------|-------------|
| **Work** | 💼 | Maximum brightness, cool temperature for focus |
| **Cinema** | 🎬 | Dim main light with blue ambient for movies |
| **Relax** | 🌙 | Warm, medium brightness for evening |
| **Sleep** | 😴 | Very dim, warm light before bed |
| **Gaming** | 🎮 | Balanced with purple ambient glow |
| **Reading** | 📖 | Bright, neutral temperature |
| **Meeting** | 👔 | Professional lighting for video calls |
| **Presentation** | 📊 | Maximum brightness, cool white |
| **Meditation** | 🧘 | Minimal, warm ambient light |

### ⚡ Automation
- **Turn off on sleep** - Automatically turn off lights when display sleeps
- **Restore on wake** - Restore previous light state when display wakes
- **Scheduled modes** - Set automatic lighting changes based on time of day

### 📡 Device Management
- **Auto discovery** - Automatically finds your light bar on the network via SSDP
- **Auto connect** - Connects to your last used device on startup
- **Manual IP entry** - Add devices manually if auto-discovery doesn't work

---

## 📋 Requirements

- **macOS 13.0 (Ventura)** or later
- **Yeelight Monitor Light Bar** or **Light Bar Pro**
- **LAN Control enabled** in Yeelight mobile app
- Same **Wi-Fi network** as your Mac

---

## 📥 Installation

### Option 1: Download from App Store
Coming soon!

### Option 2: Download from Releases
1. Go to [Releases](https://github.com/kaanyildizkan/LightBarControl/releases)
2. Download the latest `.dmg` file
3. Open the DMG and drag **LightBar Control** to Applications
4. Launch from Applications folder

### Option 3: Build from Source
```bash
# Clone the repository
git clone https://github.com/kaanyildizkan/LightBarControl.git

# Navigate to the project directory
cd LightBarControl

# Open in Xcode
open YeelightController.xcodeproj

# Build and run (⌘ + R)
```

---

## 🔧 Setup

### Step 1: Enable LAN Control on Your Light Bar

1. Open the **Yeelight** app on your phone
2. Select your **Monitor Light Bar**
3. Go to **Settings** (gear icon)
4. Find **LAN Control** or **Developer Mode**
5. **Enable** this option

### Step 2: Connect LightBar Control

1. Launch **LightBar Control**
2. Click **Search Devices**
3. Select your light bar from the list
4. Done! Your light bar is now connected

---

## 📸 Screenshots

<p align="center">
  <img src="assets/screenshot-main-on.png" alt="Main Screen - Lights On" width="280">
  <img src="assets/screenshot-main-off.png" alt="Main Screen - Lights Off" width="280">
</p>

<p align="center">
  <img src="assets/screenshot-settings.png" alt="Settings" width="280">
  <img src="assets/screenshot-discovery.png" alt="Device Discovery" width="280">
</p>

---

## 🏗️ Project Structure

```
YeelightController/
├── YeelightControllerApp.swift       # Main app entry point
├── Models/
│   ├── YeelightDevice.swift          # Device model
│   ├── DeviceState.swift             # Device state
│   ├── YeelightCommand.swift         # API commands
│   ├── YeelightResponse.swift        # API responses
│   ├── LightPreset.swift             # Light presets
│   ├── LightMode.swift               # Smart modes
│   └── LightSchedule.swift           # Schedules
├── Services/
│   ├── DeviceDiscoveryService.swift  # SSDP discovery
│   ├── YeelightConnectionManager.swift # TCP connection
│   ├── YeelightAPIService.swift      # API layer
│   ├── SettingsService.swift         # Settings management
│   ├── SystemEventMonitor.swift      # Sleep/wake detection
│   └── ScheduleManager.swift         # Schedule management
├── ViewModels/
│   └── DeviceViewModel.swift         # Main view model
└── Views/
    ├── MenuBarPopoverView.swift      # Main menu bar UI
    ├── MainLightControlView.swift    # Main light controls
    ├── AmbientLightControlView.swift # Ambient light controls
    ├── QuickModesView.swift          # Quick mode buttons
    ├── TimerView.swift               # Sleep timer
    ├── PresetListView.swift          # Presets
    ├── DiscoveryView.swift           # Device discovery
    └── SettingsView.swift            # Settings
```

---

## 🔌 Yeelight LAN Protocol

This app communicates with your light bar using the Yeelight LAN protocol:

- **Connection**: TCP on port 55443
- **Format**: JSON commands terminated with `\r\n`
- **Discovery**: SSDP multicast on 239.255.255.250:1982

### Example Commands

```json
// Turn on main light
{"id":1,"method":"set_power","params":["on","smooth",500]}

// Set brightness to 80%
{"id":1,"method":"set_bright","params":[80,"smooth",500]}

// Set color temperature to 4500K
{"id":1,"method":"set_ct_abx","params":[4500,"smooth",500]}

// Set ambient light to red
{"id":1,"method":"bg_set_rgb","params":[16711680,"smooth",500]}
```

---

## 🔒 Privacy

LightBar Control respects your privacy:

- ✅ **No data collection** - We don't collect any personal data
- ✅ **No analytics** - No tracking or analytics
- ✅ **Local only** - All communication stays on your local network
- ✅ **No internet required** - Works completely offline

Read our full [Privacy Policy](PRIVACY.md).

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 🐛 Issues & Support

If you encounter any issues or have feature requests:

- 🐛 **Bug Reports**: [Open an issue](https://github.com/kaanyildizkan/LightBarControl/issues/new?template=bug_report.md)
- 💡 **Feature Requests**: [Open an issue](https://github.com/kaanyildizkan/LightBarControl/issues/new?template=feature_request.md)
- 💬 **Discussions**: [Start a discussion](https://github.com/kaanyildizkan/LightBarControl/discussions)

---

## ☕ Support the Project

If you find this app useful, consider buying me a coffee!

<a href="https://buymeacoffee.com/morphmind">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200">
</a>

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Yeelight](https://www.yeelight.com/) for the amazing Monitor Light Bar
- Built with ❤️ using SwiftUI for macOS

---

<p align="center">
  Made with ❤️ in Turkey by <a href="https://github.com/kaanyildizkan">Kaan Yildizkan</a>
</p>
