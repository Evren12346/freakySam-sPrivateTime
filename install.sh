#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_APP_PATH="$HOME/Applications/MacBook Anonymizer.app"

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "This installer is intended for macOS."
	exit 1
fi

clear_quarantine() {
	if command -v xattr >/dev/null 2>&1; then
		xattr -dr com.apple.quarantine "$@" >/dev/null 2>&1 || true
	fi
}

chmod +x "$SCRIPT_DIR/bin/macbook_anonymizer.sh"
chmod +x "$SCRIPT_DIR/MacBook Anonymizer.command"
if [[ -f "$SCRIPT_DIR/Install MacBook Anonymizer.command" ]]; then
	chmod +x "$SCRIPT_DIR/Install MacBook Anonymizer.command"
fi
if [[ -f "$SCRIPT_DIR/install-from-github.sh" ]]; then
	chmod +x "$SCRIPT_DIR/install-from-github.sh"
fi
if [[ -f "$SCRIPT_DIR/generate_macos_icon.sh" ]]; then
	chmod +x "$SCRIPT_DIR/generate_macos_icon.sh"
fi
if [[ -f "$SCRIPT_DIR/package_macos_release.sh" ]]; then
	chmod +x "$SCRIPT_DIR/package_macos_release.sh"
fi
if [[ -f "$SCRIPT_DIR/real_macos_smoke_test.sh" ]]; then
	chmod +x "$SCRIPT_DIR/real_macos_smoke_test.sh"
fi
chmod +x "$SCRIPT_DIR/build_macos_app.sh"

clear_quarantine "$SCRIPT_DIR/MacBook Anonymizer.command"
clear_quarantine "$SCRIPT_DIR/Install MacBook Anonymizer.command"

echo "Installing dependencies..."
"$SCRIPT_DIR/bin/macbook_anonymizer.sh" install

if command -v osacompile >/dev/null 2>&1; then
	if "$SCRIPT_DIR/build_macos_app.sh" --install-to-home-applications >/dev/null; then
		echo "Built app bundle: $SCRIPT_DIR/MacBook Anonymizer.app"
	fi
fi

if [[ -d "$HOME_APP_PATH" ]]; then
	clear_quarantine "$HOME_APP_PATH"
fi

echo "Running diagnostics..."
"$SCRIPT_DIR/bin/macbook_anonymizer.sh" doctor || true

echo
echo "Install complete."
echo "Open the menu by double-clicking: $SCRIPT_DIR/MacBook Anonymizer.command"
if [[ -d "$SCRIPT_DIR/MacBook Anonymizer.app" ]]; then
	echo "App bundle: $SCRIPT_DIR/MacBook Anonymizer.app"
fi
if [[ -d "$HOME_APP_PATH" ]]; then
	echo "Launchpad-ready app: $HOME_APP_PATH"
	echo "You can launch it from Finder, Launchpad, or Applications."
fi
echo "Run: $SCRIPT_DIR/bin/macbook_anonymizer.sh doctor"
echo "Run: $SCRIPT_DIR/bin/macbook_anonymizer.sh self-test"
echo "Run: $SCRIPT_DIR/bin/macbook_anonymizer.sh start"
echo "Note: hostname cloak/restore commands may prompt for administrator privileges on macOS."
echo "Menu launcher: $SCRIPT_DIR/MacBook Anonymizer.command"
echo "If macOS blocks a launcher, right-click it and choose Open once."
