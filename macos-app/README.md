# MacBook Anonymizer - Native macOS App

A beautiful, native SwiftUI application for managing Tor anonymity on macOS.

## Building the App

### Prerequisites
- macOS 12 or later
- Xcode 13+ with SwiftUI support
- The base MacBook Anonymizer installation

### Build from Source

Using Swift Package Manager:
```bash
cd macos-app
swift build -c release
```

Using Xcode:
```bash
open Package.swift
# Xcode will open the Swift package. Build using Cmd+B.
```

### Installation

1. Build the app (see above)
2. The built binary will be in `.build/release/MacBookAnonymizer`
3. Copy to Applications:
```bash
cp .build/release/MacBookAnonymizer ~/Applications/
```

## Features

- **Beautiful Dashboard**: Modern dark-themed interface with clear status indicators
- **One-Click Controls**: Start/Stop Tor with a single click
- **Quick Actions**: Fast access to diagnostics, testing, and privacy reports
- **Live Output**: Real-time command output in the Status tab
- **System Integration**: Dock icon, proper macOS app lifecycle
- **Responsive Design**: Clean tabs and organized controls

## Architecture

- **App.swift**: Entry point and window setup
- **Models/AppManager.swift**: State management and shell command execution
- **Views/ContentView.swift**: Main UI with Dashboard, Controls, and Status tabs

## Integration with Base Script

The app automatically locates and executes the base `macbook_anonymizer.sh` script. It expects the script at:
- `~/Applications/MacBook Anonymizer/bin/macbook_anonymizer.sh` (GitHub installer path)
- Or relative to the app bundle in development

## Troubleshooting

If commands fail:
1. Ensure the base installation is complete: `~/Applications/MacBook Anonymizer/install.sh`
2. Check that Tor is installed: `which tor`
3. Try running commands directly in Terminal:
   ```bash
   ~/Applications/Si\ Or\ No\ Goobledygook/bin/macbook_anonymizer.sh status
   ```

## Signing and Distribution

For distribution, you can code sign and notarize:

```bash
# Sign the app
codesign --deep --force --verify --verbose --sign "Developer ID Application" \
  ~/Applications/MacBookAnonymizer.app

# Notarize (requires Apple Developer account)
xcrun notarytool submit MacBookAnonymizer.zip --key-chain-profile AC_PASSWORD --wait
```
