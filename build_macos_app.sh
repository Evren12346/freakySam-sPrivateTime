#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Freaky Sams Private Time"
APP_PATH="$SCRIPT_DIR/${APP_NAME}.app"
COMMAND_PATH="$SCRIPT_DIR/Freaky Sams Private Time.command"
HOME_APPLICATIONS_DIR="$HOME/Applications"
INSTALL_TO_HOME_APPLICATIONS="false"

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

chmod +x "$COMMAND_PATH"
rm -rf "$APP_PATH"

osacompile -o "$APP_PATH" <<EOF
 tell application "Terminal"
   activate
   do script quoted form of POSIX path of "$COMMAND_PATH"
 end tell
EOF

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
