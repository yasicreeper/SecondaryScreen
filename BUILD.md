# Build Scripts for Secondary Screen

## Windows EXE Build

### Prerequisites
- .NET 8.0 SDK installed
- Visual Studio 2022 (optional, for debugging)

### Build Instructions

1. Open PowerShell and navigate to the WindowsApp directory
2. Run the build command:

```powershell
cd WindowsApp
dotnet build -c Release
```

3. The EXE file will be located at:
   `WindowsApp\bin\Release\net8.0-windows\SecondaryScreenHost.exe`

### Create a Single-File Executable

To create a standalone EXE that doesn't require .NET installation:

```powershell
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true
```

The standalone EXE will be at:
`WindowsApp\bin\Release\net8.0-windows\win-x64\publish\SecondaryScreenHost.exe`

## iPad IPA Build

### Prerequisites
- macOS with Xcode 15 or later
- Apple Developer account (for signing)
- iOS device or simulator

### Build Instructions

1. Open Terminal and navigate to the iPadApp directory:

```bash
cd iPadApp
```

2. Open the project in Xcode:

```bash
open SecondaryScreen.xcodeproj
```

3. In Xcode:
   - Select your development team in Signing & Capabilities
   - Update the Bundle Identifier to match your team
   - Select your iPad device or "Any iOS Device"

4. Build the app:
   - Product → Archive
   - Wait for the archive to complete
   - Click "Distribute App"
   - Choose distribution method:
     - "Development" for testing on your devices
     - "Ad Hoc" for distributing to specific devices
     - "App Store" for App Store submission

5. The IPA file will be exported to your chosen location

### Alternative: Command Line Build

```bash
# Clean build
xcodebuild clean -project SecondaryScreen.xcodeproj -scheme SecondaryScreen

# Build for device
xcodebuild -project SecondaryScreen.xcodeproj \
  -scheme SecondaryScreen \
  -configuration Release \
  -archivePath ./build/SecondaryScreen.xcarchive \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/SecondaryScreen.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

## Installation

### Windows
1. Copy `SecondaryScreenHost.exe` to a folder on your PC
2. Run the executable
3. Click "Start Server" to begin accepting connections

### iPad
1. Install the IPA using:
   - Xcode (Window → Devices and Simulators → drag IPA)
   - iTunes File Sharing
   - TestFlight (for beta testing)
   - App Store (if published)

## Usage

1. Ensure both devices are on the same WiFi network
2. Start the Windows app and click "Start Server"
3. Note the IP address shown in the connection info
4. Open the iPad app
5. It will automatically search for available hosts
6. Or manually enter the IP address and click "Connect"
7. Once connected, your iPad will display as a secondary screen

## Troubleshooting

### Windows Firewall
If the iPad cannot connect, add a firewall rule:

```powershell
netsh advfirewall firewall add rule name="Secondary Screen" dir=in action=allow protocol=TCP localport=8888
```

### iPad Connection Issues
- Ensure both devices are on the same network
- Check that port 8888 is not blocked
- Try manual IP connection instead of auto-discovery
- Restart both applications

## Features

- WiFi and USB connection support (USB requires additional setup)
- Auto-discovery of Windows hosts
- Customizable resolution and quality
- Touch input support
- Low-latency screen streaming
- Clean, modern interface
