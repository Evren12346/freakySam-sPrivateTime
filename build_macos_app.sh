#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Amazing Sams Private Time"
APP_PATH="$SCRIPT_DIR/${APP_NAME}.app"
COMMAND_PATH="$SCRIPT_DIR/Amazing Sams Private Time.command"
HOME_APPLICATIONS_DIR="$HOME/Applications"
INSTALL_TO_HOME_APPLICATIONS="false"
ICON_SOURCE_PATH="$SCRIPT_DIR/assets/amazing-sams-private-time-icon.svg"
ICON_FILE_NAME="AmazingSamsPrivateTime.icns"
ICON_DEST_PATH="$APP_PATH/Contents/Resources/$ICON_FILE_NAME"

if [[ "${1:-}" == "--install-to-home-applications" ]]; then
  INSTALL_TO_HOME_APPLICATIONS="true"
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This builder must be run on macOS."
  exit 1
fi

if ! command -v osacompile >/dev/null 2>&1; then
  echo "osacompile is required and should be available on macOS."
  exit 1
fi

apply_custom_icon() {
  local icon_path="$1"
  if [[ ! -f "$icon_path" ]]; then
    return 1
  fi
  mkdir -p "$APP_PATH/Contents/Resources"
  cp "$icon_path" "$ICON_DEST_PATH"
  if [[ -x /usr/libexec/PlistBuddy ]]; then
    /usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$APP_PATH/Contents/Info.plist" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string $ICON_FILE_NAME" "$APP_PATH/Contents/Info.plist" >/dev/null 2>&1 || true
  fi
}

maybe_generate_icon() {
  local generated_icon_path="$SCRIPT_DIR/assets/$ICON_FILE_NAME"
  if [[ -f "$generated_icon_path" ]]; then
    echo "$generated_icon_path"
    return 0
  fi
  if [[ -f "$ICON_SOURCE_PATH" && -x "$SCRIPT_DIR/generate_macos_icon.sh" ]]; then
    "$SCRIPT_DIR/generate_macos_icon.sh" >/dev/null
  fi
  if [[ -f "$generated_icon_path" ]]; then
    echo "$generated_icon_path"
    return 0
  fi
  return 1
}

chmod +x "$COMMAND_PATH"
rm -rf "$APP_PATH"

osacompile -o "$APP_PATH" <<EOF
 tell application "Terminal"
   activate
   do script quoted form of POSIX path of "$COMMAND_PATH"
 end tell
EOF

if generated_icon="$(maybe_generate_icon 2>/dev/null)"; then
  apply_custom_icon "$generated_icon" || true
fi

if command -v xattr >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "$APP_PATH" >/dev/null 2>&1 || true
fi

if [[ "$INSTALL_TO_HOME_APPLICATIONS" == "true" ]]; then
  TARGET_APP_PATH="$HOME_APPLICATIONS_DIR/${APP_NAME}.app"
  mkdir -p "$HOME_APPLICATIONS_DIR"
  rm -rf "$TARGET_APP_PATH"
  cp -R "$APP_PATH" "$TARGET_APP_PATH"
  if command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "$TARGET_APP_PATH" >/dev/null 2>&1 || true
  fi
  echo "Installed app bundle to: $TARGET_APP_PATH"
fi

echo "Created: $APP_PATH"
