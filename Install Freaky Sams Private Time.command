#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/install.sh"
MENU_LAUNCHER="$SCRIPT_DIR/Freaky Sams Private Time.command"

chmod +x "$INSTALLER"
chmod +x "$MENU_LAUNCHER"

clear
echo "Freaky Sams Private Time"
echo "macOS installer"
echo

"$INSTALLER"

echo
read -r -p "Open the interactive menu now? [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
	"$MENU_LAUNCHER"
fi