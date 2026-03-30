#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="MacBook Anonymizer"
APP_PATH="$SCRIPT_DIR/${APP_NAME}.app"
DIST_DIR="$SCRIPT_DIR/dist"
ZIP_PATH="$DIST_DIR/${APP_NAME}.zip"
SIGNED_APP="false"
NOTARIZED_APP="false"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This packaging script must be run on macOS."
  exit 1
fi

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    exit 1
  fi
}

require_cmd ditto
require_cmd shasum

mkdir -p "$DIST_DIR"

chmod +x "$SCRIPT_DIR/build_macos_app.sh"
if [[ -x "$SCRIPT_DIR/generate_macos_icon.sh" ]]; then
  "$SCRIPT_DIR/generate_macos_icon.sh" >/dev/null || true
fi
"$SCRIPT_DIR/build_macos_app.sh"

if [[ -n "${APPLE_SIGN_IDENTITY:-}" ]]; then
  require_cmd codesign
  codesign --force --deep --timestamp --options runtime --sign "$APPLE_SIGN_IDENTITY" "$APP_PATH"
  SIGNED_APP="true"
fi

rm -f "$ZIP_PATH" "$ZIP_PATH.sha256"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

if [[ -n "${APPLE_NOTARY_PROFILE:-}" ]]; then
  require_cmd xcrun
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$APPLE_NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_PATH"
  NOTARIZED_APP="true"
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  require_cmd xcrun
  xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$APP_PATH"
  NOTARIZED_APP="true"
fi

echo "Packaged app: $APP_PATH"
echo "Packaged zip: $ZIP_PATH"
echo "Checksum: $ZIP_PATH.sha256"
echo "Signed: $SIGNED_APP"
echo "Notarized: $NOTARIZED_APP"