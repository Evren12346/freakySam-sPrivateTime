#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"
SOURCE_SVG="$ASSETS_DIR/freaky-sams-private-time-icon.svg"
OUTPUT_ICNS="$ASSETS_DIR/FreakySamsPrivateTime.icns"
TMP_DIR="$(mktemp -d)"
PNG_PATH="$TMP_DIR/source.png"
ICONSET_DIR="$TMP_DIR/FreakySamsPrivateTime.iconset"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This icon generator must be run on macOS."
  exit 1
fi

for cmd in qlmanage sips iconutil; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    exit 1
  fi
done

if [[ ! -f "$SOURCE_SVG" ]]; then
  echo "Missing icon source: $SOURCE_SVG"
  exit 1
fi

mkdir -p "$ASSETS_DIR" "$ICONSET_DIR"
qlmanage -t -s 1024 -o "$TMP_DIR" "$SOURCE_SVG" >/dev/null 2>&1

if [[ ! -f "$TMP_DIR/$(basename "$SOURCE_SVG").png" ]]; then
  echo "Failed to rasterize SVG icon source."
  exit 1
fi

mv "$TMP_DIR/$(basename "$SOURCE_SVG").png" "$PNG_PATH"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$PNG_PATH" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
  double_size=$((size * 2))
  sips -z "$double_size" "$double_size" "$PNG_PATH" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"
echo "Created: $OUTPUT_ICNS"