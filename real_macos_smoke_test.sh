#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="$SCRIPT_DIR/bin/si_or_no_goobledygook.sh"
LOG_DIR="$SCRIPT_DIR/test_logs"
LOG_FILE="$LOG_DIR/real-macos-smoke-test-$(date +%Y%m%d%H%M%S).log"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This smoke test must be run on macOS."
  exit 1
fi

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

cleanup() {
  echo
  echo "Running cleanup..."
  "$TOOL" stop >/dev/null 2>&1 || "$TOOL" panic-stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Real macOS smoke test"
echo "Log: $LOG_FILE"
echo

chmod +x "$TOOL"
chmod +x "$SCRIPT_DIR/build_macos_app.sh"

echo "[1/7] doctor"
"$TOOL" doctor

echo
echo "[2/7] privacy-report"
"$TOOL" privacy-report

echo
echo "[3/7] safe-apps"
"$TOOL" safe-apps

echo
echo "[4/7] build app bundle"
"$SCRIPT_DIR/build_macos_app.sh" --install-to-home-applications

echo
echo "[5/7] self-test"
"$TOOL" self-test

echo
echo "[6/7] explicit start/status/test"
"$TOOL" start
"$TOOL" status
"$TOOL" test

echo
echo "[7/7] stop"
"$TOOL" stop

echo
echo "Smoke test completed successfully."
echo "Review the log at: $LOG_FILE"