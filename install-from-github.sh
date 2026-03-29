#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="Evren12346"
REPO_NAME="freakySam-sPrivateTime"
REPO_REF="${FREAKY_INSTALL_REF:-main}"
INSTALL_DIR="${FREAKY_INSTALL_DIR:-$HOME/Applications/Freaky Sams Private Time}"
TMP_DIR="$(mktemp -d)"
PAYLOAD_DIR="$TMP_DIR/payload"
ARCHIVE_URL="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_REF}"

cleanup() {
	rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_macos() {
	if [[ "$(uname -s)" != "Darwin" ]]; then
		echo "This installer is intended for macOS."
		exit 1
	fi
}

require_cmd() {
	local cmd="$1"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "Missing required command: $cmd"
		exit 1
	fi
}

require_macos
require_cmd curl
require_cmd tar

mkdir -p "$PAYLOAD_DIR"

echo "Downloading ${REPO_OWNER}/${REPO_NAME} (${REPO_REF})..."
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$PAYLOAD_DIR"

EXTRACTED_DIR="$(find "$PAYLOAD_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$EXTRACTED_DIR" ]]; then
	echo "Failed to extract the repository archive."
	exit 1
fi

mkdir -p "$(dirname "$INSTALL_DIR")"
if [[ -e "$INSTALL_DIR" ]]; then
	BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
	mv "$INSTALL_DIR" "$BACKUP_DIR"
	echo "Existing install moved to: $BACKUP_DIR"
fi

mv "$EXTRACTED_DIR" "$INSTALL_DIR"

chmod +x "$INSTALL_DIR/install.sh"
chmod +x "$INSTALL_DIR/Freaky Sams Private Time.command"
chmod +x "$INSTALL_DIR/Install Freaky Sams Private Time.command"
chmod +x "$INSTALL_DIR/build_macos_app.sh"
chmod +x "$INSTALL_DIR/bin/freaky-sams-private-time.sh"

echo "Installing dependencies and preparing launchers in: $INSTALL_DIR"
"$INSTALL_DIR/install.sh"

echo
echo "Installed successfully."
echo "Menu launcher: $INSTALL_DIR/Freaky Sams Private Time.command"
echo "Interactive commands: $INSTALL_DIR/bin/freaky-sams-private-time.sh"
echo "If macOS warns about opening a downloaded launcher, right-click it and choose Open once."