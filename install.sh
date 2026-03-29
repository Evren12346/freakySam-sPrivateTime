#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "$SCRIPT_DIR/bin/freaky-sams-private-time.sh"
chmod +x "$SCRIPT_DIR/Freaky Sams Private Time.command"
chmod +x "$SCRIPT_DIR/build_macos_app.sh"
"$SCRIPT_DIR/bin/freaky-sams-private-time.sh" install

echo
echo "Install complete."
echo "Run: $SCRIPT_DIR/bin/freaky-sams-private-time.sh doctor"
echo "Run: $SCRIPT_DIR/bin/freaky-sams-private-time.sh self-test"
echo "Run: $SCRIPT_DIR/bin/freaky-sams-private-time.sh start"
echo "Note: hostname cloak/restore commands may prompt for administrator privileges on macOS."
echo "Menu launcher: $SCRIPT_DIR/Freaky Sams Private Time.command"
