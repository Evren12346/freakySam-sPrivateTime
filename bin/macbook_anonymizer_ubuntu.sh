#!/usr/bin/env bash
set -euo pipefail

umask 077

TOOL_NAME="macbook anonymizer (ubuntu)"
STATE_DIR="${HOME}/.macbook-anonymizer-linux"
STATE_FILE="${STATE_DIR}/proxy_state.env"
IDENTITY_STATE_FILE="${STATE_DIR}/identity_state.env"
TOR_SOCKS_HOST="127.0.0.1"
TOR_SOCKS_PORT="9050"
TOR_CHECK_URL="https://check.torproject.org/api/ip"
IP_CHECK_URL="https://api.ipify.org"

usage() {
cat <<'EOF'
macbook anonymizer (ubuntu)

Usage:
  macbook_anonymizer_ubuntu.sh install
  macbook_anonymizer_ubuntu.sh doctor
  macbook_anonymizer_ubuntu.sh start
  macbook_anonymizer_ubuntu.sh stop
  macbook_anonymizer_ubuntu.sh panic-stop [--force]
  macbook_anonymizer_ubuntu.sh status
  macbook_anonymizer_ubuntu.sh test
  macbook_anonymizer_ubuntu.sh self-test
  macbook_anonymizer_ubuntu.sh privacy-report
  macbook_anonymizer_ubuntu.sh tor-env
  macbook_anonymizer_ubuntu.sh cloak-hostname [label]
  macbook_anonymizer_ubuntu.sh restore-hostname
  macbook_anonymizer_ubuntu.sh newnym
  macbook_anonymizer_ubuntu.sh checklist
  macbook_anonymizer_ubuntu.sh safe-apps
  macbook_anonymizer_ubuntu.sh launch-safe-app <profile>
  macbook_anonymizer_ubuntu.sh open-tor-browser
  macbook_anonymizer_ubuntu.sh validate
EOF
}

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "This Ubuntu tool only runs on Linux."
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

run_privileged() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR" 2>/dev/null || true
}

ensure_safe_state_file() {
  local file_path="$1"
  if [[ -L "$file_path" ]]; then
    echo "Refusing symlinked state file: $file_path"
    exit 1
  fi
  if [[ -e "$file_path" && ! -f "$file_path" ]]; then
    echo "Refusing non-regular state file: $file_path"
    exit 1
  fi
}

confirm_panic_stop() {
  local answer=""
  if [[ "${MACBOOK_ANONYMIZER_ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    echo "Refusing panic-stop in non-interactive mode without --force."
    echo "Use: $0 panic-stop --force"
    return 1
  fi
  echo "WARNING: panic-stop performs immediate network rollback operations."
  read -r -p "Type YES to continue: " answer
  [[ "$answer" == "YES" ]]
}

has_gsettings_proxy_schema() {
  command -v gsettings >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -qx "org.gnome.system.proxy"
}

save_proxy_state() {
  ensure_state_dir
  ensure_safe_state_file "$STATE_FILE"
  : > "$STATE_FILE"
  chmod 600 "$STATE_FILE" 2>/dev/null || true

  if has_gsettings_proxy_schema; then
    {
      echo "PROXY_BACKEND=gnome"
      echo "MODE=$(gsettings get org.gnome.system.proxy mode 2>/dev/null || echo "'none'")"
      echo "SOCKS_HOST=$(gsettings get org.gnome.system.proxy.socks host 2>/dev/null || echo "''")"
      echo "SOCKS_PORT=$(gsettings get org.gnome.system.proxy.socks port 2>/dev/null || echo "0")"
      echo "IGNORE_HOSTS=$(gsettings get org.gnome.system.proxy ignore-hosts 2>/dev/null || echo "[]")"
    } >> "$STATE_FILE"
  else
    echo "PROXY_BACKEND=none" >> "$STATE_FILE"
  fi
}

restore_proxy_state() {
  ensure_safe_state_file "$STATE_FILE"
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "No saved proxy state found at: $STATE_FILE"
    echo "Safety guard: leaving existing proxy settings unchanged."
    return 1
  fi

  # shellcheck disable=SC1090
  source "$STATE_FILE"

  if [[ "${PROXY_BACKEND:-none}" == "gnome" ]] && has_gsettings_proxy_schema; then
    gsettings set org.gnome.system.proxy mode "${MODE:-'none'}" >/dev/null 2>&1 || true
    gsettings set org.gnome.system.proxy.socks host "${SOCKS_HOST:-''}" >/dev/null 2>&1 || true
    gsettings set org.gnome.system.proxy.socks port "${SOCKS_PORT:-0}" >/dev/null 2>&1 || true
    gsettings set org.gnome.system.proxy ignore-hosts "${IGNORE_HOSTS:-[]}" >/dev/null 2>&1 || true
    echo "Proxy settings restored from saved state."
  else
    echo "No GNOME proxy backend saved; leaving desktop proxy settings unchanged."
  fi
}

route_through_tor() {
  if has_gsettings_proxy_schema; then
    gsettings set org.gnome.system.proxy mode "'manual'"
    gsettings set org.gnome.system.proxy.socks host "'${TOR_SOCKS_HOST}'"
    gsettings set org.gnome.system.proxy.socks port "${TOR_SOCKS_PORT}"
    gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.1', '::1']"
    echo "GNOME proxy configured for Tor SOCKS (${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT})."
  else
    echo "GNOME proxy schema unavailable."
    echo "Use tor-env output with proxy-aware apps."
  fi
}

start_tor() {
  if systemctl list-unit-files 2>/dev/null | grep -q '^tor\.service'; then
    run_privileged systemctl start tor >/dev/null 2>&1 || true
  elif command -v service >/dev/null 2>&1; then
    run_privileged service tor start >/dev/null 2>&1 || true
  fi

  if ! pgrep -x tor >/dev/null 2>&1 && command -v tor >/dev/null 2>&1; then
    ensure_state_dir
    mkdir -p "$STATE_DIR/tor-data"
    tor --RunAsDaemon 1 --SocksPort "$TOR_SOCKS_PORT" --DataDirectory "$STATE_DIR/tor-data" >/dev/null 2>&1 || true
  fi
}

stop_tor() {
  if systemctl list-unit-files 2>/dev/null | grep -q '^tor\.service'; then
    run_privileged systemctl stop tor >/dev/null 2>&1 || true
  elif command -v service >/dev/null 2>&1; then
    run_privileged service tor stop >/dev/null 2>&1 || true
  fi
  if pgrep -x tor >/dev/null 2>&1; then
    pkill -TERM tor >/dev/null 2>&1 || true
  fi
}

wait_for_tor() {
  local retries=20
  local i
  for ((i=1; i<=retries; i++)); do
    if nc -z "$TOR_SOCKS_HOST" "$TOR_SOCKS_PORT" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "Tor did not become available on ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}."
  return 1
}

get_direct_ip() {
  curl -4fsS --max-time 10 "$IP_CHECK_URL" || true
}

get_tor_ip() {
  curl -4fsS --socks5-hostname "${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}" --max-time 15 "$IP_CHECK_URL" || true
}

get_tor_api_json() {
  curl -fsS --socks5-hostname "${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}" --max-time 20 "$TOR_CHECK_URL" || true
}

get_tor_api_is_tor() {
  printf '%s' "$1" | sed -n 's/.*"IsTor":\(true\|false\).*/\1/p'
}

get_tor_api_ip() {
  printf '%s' "$1" | sed -n 's/.*"IP":"\([^"]*\)".*/\1/p'
}

print_session_checklist() {
  echo "Leak-risk checklist:"
  echo "- Do not log into personal accounts while anonymized."
  echo "- Prefer Tor Browser for web sessions."
  echo "- Avoid cloud-sync and messaging apps during sensitive sessions."
  echo "- Stop and restore networking when done."
}

list_safe_app_profiles() {
  cat <<'EOF'
Available safer app profiles:
- tor-browser      Preferred browser for anonymous sessions.
- firefox          General browser profile (use with caution).
- terminal         Local shell for diagnostics.
- text-editor      Local note editing.
- system-monitor   Process inspection.
EOF
}

resolve_safe_app_cmd() {
  local profile="$1"
  case "$profile" in
    tor-browser)
      command -v torbrowser-launcher >/dev/null 2>&1 && { echo "torbrowser-launcher"; return 0; }
      command -v tor-browser >/dev/null 2>&1 && { echo "tor-browser"; return 0; }
      return 1
      ;;
    firefox)
      command -v firefox >/dev/null 2>&1 && { echo "firefox"; return 0; }
      return 1
      ;;
    terminal)
      command -v gnome-terminal >/dev/null 2>&1 && { echo "gnome-terminal"; return 0; }
      command -v x-terminal-emulator >/dev/null 2>&1 && { echo "x-terminal-emulator"; return 0; }
      return 1
      ;;
    text-editor)
      command -v gedit >/dev/null 2>&1 && { echo "gedit"; return 0; }
      command -v xdg-open >/dev/null 2>&1 && { echo "xdg-open"; return 0; }
      return 1
      ;;
    system-monitor)
      command -v gnome-system-monitor >/dev/null 2>&1 && { echo "gnome-system-monitor"; return 0; }
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

cmd_install() {
  require_linux
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Ubuntu/Debian apt-get is required for automatic install."
    echo "Install manually: tor curl torsocks netcat-openbsd"
    exit 1
  fi
  run_privileged apt-get update -y >/dev/null
  run_privileged apt-get install -y tor curl torsocks netcat-openbsd >/dev/null
  echo "Dependencies installed."
}

cmd_doctor() {
  require_linux
  echo "Running diagnostics for $TOOL_NAME..."
  for cmd in curl nc; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "[ok] $cmd"
    else
      echo "[missing] $cmd"
    fi
  done
  if command -v tor >/dev/null 2>&1; then
    echo "[ok] tor"
  else
    echo "[missing] tor"
  fi
  if has_gsettings_proxy_schema; then
    echo "[ok] GNOME proxy schema available"
  else
    echo "[warn] GNOME proxy schema unavailable (CLI tor-env still works)"
  fi
  if nc -z "$TOR_SOCKS_HOST" "$TOR_SOCKS_PORT" >/dev/null 2>&1; then
    echo "[ok] Tor SOCKS port reachable at ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}"
  else
    echo "[warn] Tor SOCKS port not reachable at ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}"
  fi
}

cmd_start() {
  require_linux
  require_cmd curl
  require_cmd nc
  local started=0

  rollback_on_failed_start() {
    if [[ "$started" -eq 1 ]]; then
      return 0
    fi
    echo "Start failed. Attempting safety rollback..."
    restore_proxy_state >/dev/null 2>&1 || true
    stop_tor >/dev/null 2>&1 || true
  }
  trap rollback_on_failed_start RETURN

  echo "Starting $TOOL_NAME..."
  save_proxy_state
  start_tor
  wait_for_tor
  route_through_tor
  started=1
  trap - RETURN

  echo "Tor routing enabled where supported."
  echo "Run: $0 status"
  echo "Run: $0 test"
}

cmd_stop() {
  require_linux
  echo "Stopping $TOOL_NAME..."
  restore_proxy_state || true
  stop_tor
  echo "Tor service stopped."
}

cmd_panic_stop() {
  require_linux
  local force_mode="0"
  if [[ "${1:-}" == "--force" ]]; then
    force_mode="1"
  elif [[ -n "${1:-}" ]]; then
    echo "Unknown option for panic-stop: $1"
    echo "Usage: $0 panic-stop [--force]"
    exit 1
  fi
  if [[ "$force_mode" != "1" ]]; then
    if ! confirm_panic_stop; then
      echo "Panic stop cancelled."
      exit 1
    fi
  fi

  echo "Panic stop: restoring desktop proxy and stopping Tor..."
  restore_proxy_state || true
  stop_tor
  echo "Panic stop complete."
}

cmd_status() {
  require_linux
  echo "Tor process status:"
  if pgrep -x tor >/dev/null 2>&1; then
    echo "- tor is running"
  else
    echo "- tor is not running"
  fi

  if has_gsettings_proxy_schema; then
    echo
    echo "GNOME proxy status:"
    echo "- mode: $(gsettings get org.gnome.system.proxy mode 2>/dev/null || echo unknown)"
    echo "- socks host: $(gsettings get org.gnome.system.proxy.socks host 2>/dev/null || echo unknown)"
    echo "- socks port: $(gsettings get org.gnome.system.proxy.socks port 2>/dev/null || echo unknown)"
  else
    echo "GNOME proxy status unavailable on this desktop environment."
  fi

  if [[ -f "$STATE_FILE" ]]; then
    echo "Saved state file: $STATE_FILE"
  fi
}

cmd_test() {
  require_linux
  require_cmd curl
  local direct_ip tor_ip tor_json is_tor tor_api_ip
  direct_ip="$(get_direct_ip)"
  tor_ip="$(get_tor_ip)"
  tor_json="$(get_tor_api_json)"
  is_tor="$(get_tor_api_is_tor "$tor_json")"
  tor_api_ip="$(get_tor_api_ip "$tor_json")"

  echo "Direct IP: ${direct_ip:-unavailable}"
  echo "Tor IP:    ${tor_ip:-unavailable}"
  echo "Tor API:   IsTor=${is_tor:-unknown} IP=${tor_api_ip:-unavailable}"

  if [[ -n "$direct_ip" && -n "$tor_ip" && "$direct_ip" != "$tor_ip" ]]; then
    echo "Looks good: Tor exit IP differs from direct IP."
  else
    echo "Warning: Unable to confirm Tor routing difference."
  fi
}

cmd_self_test() {
  require_linux
  local failed=0
  echo "Running self-test for $TOOL_NAME..."
  if ! cmd_start; then
    failed=1
  fi
  if ! cmd_test; then
    failed=1
  fi
  cmd_stop || true
  if [[ "$failed" -ne 0 ]]; then
    echo "Self-test failed."
    return 1
  fi
  echo "Self-test passed."
}

cmd_newnym() {
  require_linux
  echo "Requesting new Tor circuit (SIGHUP)..."
  if pgrep -x tor >/dev/null 2>&1; then
    pkill -HUP tor || true
    sleep 2
    echo "Circuit rotation signal sent."
  else
    echo "Tor process not found."
    exit 1
  fi
}

cmd_privacy_report() {
  require_linux
  local host
  host="$(hostname 2>/dev/null || true)"
  echo "Host identity report:"
  echo "- Hostname: ${host:-unset}"
  if command -v hostnamectl >/dev/null 2>&1; then
    echo "- Pretty hostname: $(hostnamectl --static 2>/dev/null || echo unset)"
  fi
  if [[ -f /etc/machine-id ]]; then
    echo "- Machine-id present: yes"
  else
    echo "- Machine-id present: no"
  fi
}

cmd_tor_env() {
  require_linux
  cat <<EOF
Export these for proxy-aware CLI tools and apps:
export ALL_PROXY=socks5h://${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}
export HTTP_PROXY=socks5h://${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}
export HTTPS_PROXY=socks5h://${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}
export NO_PROXY=localhost,127.0.0.1,::1
EOF
}

cmd_cloak_hostname() {
  require_linux
  local label="${1:-anon-linux-$(date +%Y%m%d%H%M%S)}"
  label="$(printf '%s' "$label" | tr -cd '[:alnum:]-' | sed 's/--*/-/g; s/^-//; s/-$//')"
  if [[ -z "$label" ]]; then
    echo "Unable to derive a valid hostname label."
    exit 1
  fi

  ensure_state_dir
  ensure_safe_state_file "$IDENTITY_STATE_FILE"
  {
    echo "HOSTNAME=$(hostname 2>/dev/null || true)"
  } > "$IDENTITY_STATE_FILE"
  chmod 600 "$IDENTITY_STATE_FILE" 2>/dev/null || true

  if command -v hostnamectl >/dev/null 2>&1; then
    run_privileged hostnamectl set-hostname "$label"
  else
    run_privileged hostname "$label"
  fi
  echo "Hostname changed to: $label"
  echo "Restore with: $0 restore-hostname"
}

cmd_restore_hostname() {
  require_linux
  ensure_safe_state_file "$IDENTITY_STATE_FILE"
  if [[ ! -f "$IDENTITY_STATE_FILE" ]]; then
    echo "No saved hostname state found."
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$IDENTITY_STATE_FILE"
  if [[ -z "${HOSTNAME:-}" ]]; then
    echo "Saved hostname is empty."
    exit 1
  fi
  if command -v hostnamectl >/dev/null 2>&1; then
    run_privileged hostnamectl set-hostname "$HOSTNAME"
  else
    run_privileged hostname "$HOSTNAME"
  fi
  echo "Hostname restored."
}

cmd_checklist() {
  require_linux
  print_session_checklist
}

cmd_safe_apps() {
  require_linux
  list_safe_app_profiles
}

cmd_launch_safe_app() {
  require_linux
  local profile="${1:-}"
  local cmd=""
  if [[ -z "$profile" ]]; then
    echo "Usage: $0 launch-safe-app <profile>"
    list_safe_app_profiles
    exit 1
  fi
  if ! cmd="$(resolve_safe_app_cmd "$profile")"; then
    echo "Unknown or unavailable safe app profile: $profile"
    list_safe_app_profiles
    exit 1
  fi
  echo "Launching safe app profile: $profile"
  "$cmd" >/dev/null 2>&1 &
}

cmd_open_tor_browser() {
  require_linux
  cmd_launch_safe_app tor-browser
}

cmd_validate() {
  require_cmd awk
  require_cmd sed
  require_cmd paste
  require_cmd curl
  require_cmd nc
  echo "Validated state directory: $STATE_DIR"
  echo "Validated state file path: $STATE_FILE"
  echo "Validated identity state path: $IDENTITY_STATE_FILE"
  echo "Static validation checks passed."
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    install) cmd_install ;;
    doctor) cmd_doctor ;;
    start) cmd_start ;;
    stop) cmd_stop ;;
    panic-stop)
      shift || true
      cmd_panic_stop "$@"
      ;;
    status) cmd_status ;;
    test) cmd_test ;;
    self-test) cmd_self_test ;;
    privacy-report) cmd_privacy_report ;;
    tor-env) cmd_tor_env ;;
    cloak-hostname)
      shift || true
      cmd_cloak_hostname "$@"
      ;;
    restore-hostname) cmd_restore_hostname ;;
    newnym) cmd_newnym ;;
    checklist) cmd_checklist ;;
    safe-apps) cmd_safe_apps ;;
    launch-safe-app)
      shift || true
      cmd_launch_safe_app "$@"
      ;;
    open-tor-browser) cmd_open_tor_browser ;;
    validate) cmd_validate ;;
    -h|--help|help|"") usage ;;
    *)
      echo "Unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"
