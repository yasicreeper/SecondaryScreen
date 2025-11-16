# Secondary Screen - iPad as Windows Secondary Display

Transform your iPad into a wireless secondary display for your Windows PC with touch input support.

## Features

### Windows Application
- 🖥️ **Virtual Display Driver Integration** - Creates a true secondary monitor
- 📡 **WiFi & USB Connectivity** - Connect via network or USB cable
- 🔍 **Auto-Discovery** - Automatically finds iPad devices on network
- ⚙️ **Comprehensive Settings** - Control resolution, quality, frame rate
- 🎨 **Clean Modern UI** - Easy-to-use WPF interface
- 🔒 **Secure Connection** - Direct peer-to-peer communication

### iPad Application
- 📱 **Native iOS/iPadOS App** - Built with SwiftUI
- 🔄 **Auto-Connect** - Automatically connects on launch (configurable)
- 👆 **Touch Input** - Use your iPad screen as a touchscreen
- 🔄 **Multiple Orientations** - Landscape and portrait support
- ⚡ **Low Latency** - Optimized streaming protocol
- 💾 **Settings Sync** - Settings controlled from Windows app

## System Requirements

### Windows
- Windows 10 or later (64-bit)
- .NET 8.0 SDK (for building) or included runtime (for running)
- Network adapter (WiFi or Ethernet)
- 4GB RAM minimum, 8GB recommended

### iPad
- iPad running iOS 14.0 or later
- WiFi connection
- Apple Developer account (for building and installing)

## Quick Start

### Building the Applications

#### Windows EXE
```powershell
# Navigate to project directory
cd SecondaryScreen

# Run build script
.\build-windows.ps1
```

The executable will be at: `Build\Installer\SecondaryScreenHost.exe`

#### iPad IPA
```bash
# On macOS, navigate to project directory
cd SecondaryScreen

# Run build script
./build-ipad.sh

# Then open Xcode Organizer to export IPA
```

See [BUILD.md](BUILD.md) for detailed build instructions.

### Installation

#### Windows
1. Run `SecondaryScreenHost.exe`
2. Allow through Windows Firewall if prompted
3. Click "Start Server"

#### iPad
1. Install IPA using Xcode, TestFlight, or App Store
2. Launch the app
3. Grant network permissions when prompted

## Usage

### First Time Setup

1. **Start Windows Server**
   - Launch SecondaryScreenHost.exe
   - Click "Start Server" button
   - Note the IP address displayed (e.g., 192.168.1.100:8888)

2. **Connect iPad**
   - Open Secondary Screen app on iPad
   - App will auto-search for servers
   - Select your PC from the list, or
   - Manually enter the IP address
   - Tap "Connect"

3. **Configure Settings**
   - In Windows app, go to Settings tab
   - Adjust resolution, quality, and frame rate
   - Enable/disable touch input
   - Settings automatically sync to iPad

### Using as Secondary Display

Once connected:
- Your iPad displays the extended desktop
- Move windows to the iPad screen from Windows
- Touch the iPad screen to control the cursor
- Pinch and gesture support (if enabled)

### Keyboard Shortcuts (Windows)

- `Win + P` - Windows display settings
- `Win + Shift + Left/Right` - Move windows between displays

## Configuration

### Windows Settings

| Setting | Description | Default |
|---------|-------------|---------|
| Resolution | Virtual display resolution | 1024x768 |
| Quality | JPEG compression quality (1-100) | 85 |
| Frame Rate | Frames per second (15-60) | 30 |
| Auto-start | Start server with Windows | Off |

### iPad Settings

| Setting | Description | Default |
|---------|-------------|---------|
| Auto-connect | Connect on app launch | On |
| Keep Screen On | Prevent screen sleep | On |
| Orientation | Display orientation lock | Auto |
| Touch Input | Enable touch control | On |

## Troubleshooting

### iPad Cannot Connect

**Check Network**
- Ensure both devices on same WiFi network
- Disable VPN on either device
- Check firewall settings

**Windows Firewall**
```powershell
# Run as Administrator
netsh advfirewall firewall add rule name="Secondary Screen" dir=in action=allow protocol=TCP localport=8888
```

**Try Manual Connection**
- Use the Windows app to find your IP
- Enter IP manually on iPad
- Format: `192.168.1.100` (without port)

### Poor Performance

**Reduce Quality**
- Lower resolution to 1024x768
- Reduce quality to 60-70
- Lower frame rate to 20-25 FPS

**Network Issues**
- Use 5GHz WiFi if available
- Reduce distance to router
- Close bandwidth-heavy applications

### Display Not Extending

The virtual display driver requires additional setup:
- Install display driver (see Advanced section)
- Or use screen duplication mode instead

## Advanced

### USB Connection

USB connection requires:
1. iTunes drivers installed on Windows
2. iPad trusted on PC
3. USB debugging enabled
4. Additional usbmuxd library

This feature is experimental and may require additional configuration.

### Virtual Display Driver

For true extended desktop:
1. Install virtual display driver (IddSample or similar)
2. Configure driver to create virtual monitor
3. Windows will recognize iPad as second monitor

Current version uses screen capture mode for simplicity.

## Architecture

### Communication Protocol

```
Windows Server (TCP 8888)
    ↓
JSON Messages + Binary Frames
    ↓
iPad Client (Network.framework)
```

**Message Types:**
- `settings` - Configuration sync
- `frame` - Screen frame data
- `touch` - Touch input events
- `info` - Device information

### Screen Capture

Windows uses GDI+ BitBlt for screen capture:
1. Capture primary display region
2. Resize to target resolution
3. Compress to JPEG
4. Stream to connected devices

Frame rate adapts to network conditions.

## Project Structure

```
SecondaryScreen/
├── WindowsApp/              # Windows WPF Application
│   ├── Core/                # Business logic
│   │   ├── ServerManager.cs
│   │   ├── ScreenCaptureService.cs
│   │   └── SettingsManager.cs
│   ├── Models/              # Data models
│   ├── MainWindow.xaml      # Main UI
│   └── App.xaml             # Application entry
│
├── iPadApp/                 # iPad iOS Application
│   └── SecondaryScreen/
│       ├── SecondaryScreenApp.swift
│       ├── ContentView.swift
│       ├── ConnectionManager.swift
│       └── Assets.xcassets/
│
├── build-windows.ps1        # Windows build script
├── build-ipad.sh           # iPad build script
├── BUILD.md                # Build instructions
└── README.md               # This file
```

## Contributing

Contributions welcome! Areas for improvement:

- [ ] USB connection implementation
- [ ] H.264 video encoding for better quality
- [ ] Multi-monitor support
- [ ] Clipboard synchronization
- [ ] Audio streaming
- [ ] Better error handling
- [ ] Performance optimizations

## License

This project is provided as-is for personal and educational use.

## Acknowledgments

Built with:
- .NET 8.0 & WPF
- SwiftUI & Network.framework
- SharpDX for screen capture
- Newtonsoft.Json for serialization

## Support

For issues, questions, or feature requests, please check:
- BUILD.md for build instructions
- Troubleshooting section above
- Create an issue in the repository

## Version History

**1.0.0** (Current)
- Initial release
- WiFi connectivity
- Basic screen streaming
- Touch input support
- Settings synchronization
- Clean modern UI

---

Made with ❤️ for productivity enthusiasts
