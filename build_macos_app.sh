#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Freaky Sams Private Time"
APP_PATH="$SCRIPT_DIR/${APP_NAME}.app"
COMMAND_PATH="$SCRIPT_DIR/Freaky Sams Private Time.command"

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

echo "Created: $APP_PATH"
