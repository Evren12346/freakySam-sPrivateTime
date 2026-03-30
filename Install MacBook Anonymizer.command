#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/install.sh"
MENU_LAUNCHER="$SCRIPT_DIR/MacBook Anonymizer.command"

chmod +x "$INSTALLER"
chmod +x "$MENU_LAUNCHER"

clear
echo "MacBook Anonymizer"
echo "macOS installer"
echo

"$INSTALLER"

echo
read -r -p "Open the interactive menu now? [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
	"$MENU_LAUNCHER"
fi