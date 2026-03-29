#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "This installer is intended for macOS."
	exit 1
fi

chmod +x "$SCRIPT_DIR/bin/freaky-sams-private-time.sh"
chmod +x "$SCRIPT_DIR/Freaky Sams Private Time.command"
if [[ -f "$SCRIPT_DIR/Install Freaky Sams Private Time.command" ]]; then
	chmod +x "$SCRIPT_DIR/Install Freaky Sams Private Time.command"
fi
chmod +x "$SCRIPT_DIR/build_macos_app.sh"

echo "Installing dependencies..."
"$SCRIPT_DIR/bin/freaky-sams-private-time.sh" install

if command -v osacompile >/dev/null 2>&1; then
	if "$SCRIPT_DIR/build_macos_app.sh" >/dev/null; then
		echo "Built app bundle: $SCRIPT_DIR/Freaky Sams Private Time.app"
	fi
fi

echo
echo "Install complete."
echo "Open the menu by double-clicking: $SCRIPT_DIR/Freaky Sams Private Time.command"
if [[ -d "$SCRIPT_DIR/Freaky Sams Private Time.app" ]]; then
	echo "App bundle: $SCRIPT_DIR/Freaky Sams Private Time.app"
	if [[ ! -e "$HOME/Applications" ]]; then
		mkdir -p "$HOME/Applications"
	fi
	echo "Optional shortcut: drag the app bundle into ~/Applications if you want it in Launchpad."
fi
echo "Run: $SCRIPT_DIR/bin/freaky-sams-private-time.sh doctor"
echo "Run: $SCRIPT_DIR/bin/freaky-sams-private-time.sh self-test"
echo "Run: $SCRIPT_DIR/bin/freaky-sams-private-time.sh start"
echo "Note: hostname cloak/restore commands may prompt for administrator privileges on macOS."
echo "Menu launcher: $SCRIPT_DIR/Freaky Sams Private Time.command"
