#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/install.sh"
MENU_LAUNCHER="$SCRIPT_DIR/Si Or No Goobledygook.command"

chmod +x "$INSTALLER"
chmod +x "$MENU_LAUNCHER"

clear
echo "Si Or No Goobledygook"
echo "macOS installer"
echo

"$INSTALLER"

echo
read -r -p "Open the interactive menu now? [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
	"$MENU_LAUNCHER"
fi