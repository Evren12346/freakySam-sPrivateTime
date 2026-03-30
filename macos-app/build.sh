#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
MACOS_MINIMUM_VERSION="12.0"

echo "🔨 Building MacBook Anonymizer macOS App..."
echo

# Clean previous builds
if [[ -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR"
fi

# Build using Swift Package Manager
echo "📦 Building with Swift Package Manager..."

cd "$SCRIPT_DIR"
swift build -c release

SWIFT_BUILD_DIR="$SCRIPT_DIR/.build/release"

if [[ -d "$SWIFT_BUILD_DIR" ]]; then
    echo "✅ Build successful!"
    echo "📍 Location: $SWIFT_BUILD_DIR"
    echo
    echo "To open this Swift package in Xcode for GUI app workflows:"
    echo "  open Package.swift"
    exit 0
fi

echo "❌ Build failed!"
exit 1
