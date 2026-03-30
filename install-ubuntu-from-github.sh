#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="Evren12346"
REPO_NAME="macbook-anonymizer"
INSTALL_DIR="${MACBOOK_ANONYMIZER_UBUNTU_INSTALL_DIR:-$HOME/Applications/MacBook Anonymizer Ubuntu}"
AUTO_LAUNCH="${MACBOOK_ANONYMIZER_AUTO_LAUNCH:-1}"
TMP_DIR="$(mktemp -d)"
PAYLOAD_DIR="$TMP_DIR/payload"
REPO_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"
REPO_REF=""
ARCHIVE_URL=""

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "This installer is intended for Linux/Ubuntu."
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

validate_install_dir() {
  if [[ -z "$INSTALL_DIR" || "$INSTALL_DIR" == "/" || "$INSTALL_DIR" == "." ]]; then
    echo "Refusing unsafe install directory: '$INSTALL_DIR'"
    exit 1
  fi
  if [[ "$INSTALL_DIR" == *$'\n'* ]]; then
    echo "Install directory contains invalid newline characters."
    exit 1
  fi
  if [[ "$INSTALL_DIR" != /* ]]; then
    echo "Install directory must be an absolute path."
    exit 1
  fi
}

resolve_release_ref() {
  local requested_ref="${MACBOOK_ANONYMIZER_INSTALL_REF:-}"
  local release_json latest_tag
  if [[ -n "$requested_ref" ]]; then
    REPO_REF="$requested_ref"
    return 0
  fi
  release_json="$(curl -fsSL "$REPO_API_URL/releases/latest" 2>/dev/null || true)"
  latest_tag="$(printf '%s' "$release_json" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  if [[ -n "$latest_tag" ]]; then
    REPO_REF="$latest_tag"
    return 0
  fi
  REPO_REF="main"
}

build_archive_url() {
  if [[ "$REPO_REF" =~ ^v[0-9] ]]; then
    ARCHIVE_URL="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/tags/${REPO_REF}"
  else
    ARCHIVE_URL="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_REF}"
  fi
}

require_linux
require_cmd curl
require_cmd tar
validate_install_dir
resolve_release_ref
build_archive_url

mkdir -p "$PAYLOAD_DIR"

echo "Downloading ${REPO_OWNER}/${REPO_NAME} (${REPO_REF})..."
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$PAYLOAD_DIR"

EXTRACTED_DIR="$(find "$PAYLOAD_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$EXTRACTED_DIR" ]]; then
  echo "Failed to extract the repository archive."
  exit 1
fi
if [[ "$(basename "$EXTRACTED_DIR")" != ${REPO_NAME}-* ]]; then
  echo "Unexpected archive layout: $(basename "$EXTRACTED_DIR")"
  exit 1
fi

mkdir -p "$(dirname "$INSTALL_DIR")"
if [[ -e "$INSTALL_DIR" ]]; then
  BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
  mv "$INSTALL_DIR" "$BACKUP_DIR"
  echo "Existing install moved to: $BACKUP_DIR"
fi

mv "$EXTRACTED_DIR" "$INSTALL_DIR"

chmod +x "$INSTALL_DIR/install-ubuntu.sh"
chmod +x "$INSTALL_DIR/install-ubuntu-from-github.sh"
chmod +x "$INSTALL_DIR/MacBook Anonymizer Ubuntu.command"
chmod +x "$INSTALL_DIR/bin/macbook_anonymizer_ubuntu.sh"

echo "Installing dependencies and preparing launchers in: $INSTALL_DIR"
"$INSTALL_DIR/bin/macbook_anonymizer_ubuntu.sh" install

echo
echo "Installed successfully."
echo "Installed version/ref: $REPO_REF"
echo "Ubuntu menu launcher: $INSTALL_DIR/MacBook Anonymizer Ubuntu.command"
echo "Interactive commands: $INSTALL_DIR/bin/macbook_anonymizer_ubuntu.sh"

if [[ "$AUTO_LAUNCH" == "1" ]]; then
  echo
  echo "Opening Ubuntu menu launcher now..."
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$INSTALL_DIR/MacBook Anonymizer Ubuntu.command" >/dev/null 2>&1 || true
  else
    "$INSTALL_DIR/MacBook Anonymizer Ubuntu.command" || true
  fi
fi
