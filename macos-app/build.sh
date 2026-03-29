#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
MACOS_MINIMUM_VERSION="12.0"

echo "🔨 Building Si Or No Goobledygook macOS App..."
echo

# Clean previous builds
if [[ -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR"
fi

# Build using Xcode if available
if command -v xcodebuild >/dev/null 2>&1; then
    echo "📦 Building with Xcode..."
    
    # Check if Xcode project exists
    if [[ -f "$SCRIPT_DIR/SiOrNoGoobledygook.xcodeproj/project.pbxproj" ]]; then
        cd "$SCRIPT_DIR"
        xcodebuild -scheme SiOrNoGoobledygook -configuration Release -derivedDataPath "$BUILD_DIR/xcode"
        
        APP_BUNDLE="$BUILD_DIR/xcode/Build/Products/Release/SiOrNoGoobledygook.app"
        
        if [[ -d "$APP_BUNDLE" ]]; then
            echo "✅ Build successful!"
            echo "📍 App location: $APP_BUNDLE"
            echo
            echo "To install to ~/Applications:"
            echo "  cp -r '$APP_BUNDLE' ~/Applications/"
            exit 0
        fi
    fi
fi

# Fallback to Swift Package Manager
echo "📦 Building with Swift Package Manager..."

cd "$SCRIPT_DIR"
swift build -c release

SWIFT_BUILD_DIR="$SCRIPT_DIR/.build/release"

if [[ -d "$SWIFT_BUILD_DIR" ]]; then
    echo "✅ Build successful (CLI version)!"
    echo "📍 Location: $SWIFT_BUILD_DIR"
    echo
    echo "Note: This is the command-line version."
    echo "For a full GUI macOS app bundle, open in Xcode and build:"
    echo "  open SiOrNoGoobledygook.xcodeproj"
    exit 0
fi

echo "❌ Build failed!"
exit 1
