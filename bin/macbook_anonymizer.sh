#!/usr/bin/env bash
set -euo pipefail

# Keep state files private by default.
umask 077

TOOL_NAME="macbook anonymizer"
STATE_DIR="${HOME}/.macbook-anonymizer"
STATE_FILE="${STATE_DIR}/proxy_state.tsv"
IDENTITY_STATE_FILE="${STATE_DIR}/identity_state.tsv"
TOR_SOCKS_HOST="127.0.0.1"
TOR_SOCKS_PORT="9050"
TOR_CHECK_URL="https://check.torproject.org/api/ip"
IP_CHECK_URL="https://api.ipify.org"
APP_SEARCH_ROOTS_DEFAULT="/Applications:${HOME}/Applications:/System/Applications:/Applications/Utilities:/System/Applications/Utilities"

usage() {
	cat <<'EOF'
macbook anonymizer

Usage:
	macbook-anonymizer.sh install
	macbook-anonymizer.sh doctor
	macbook-anonymizer.sh start
	macbook-anonymizer.sh stop
	macbook-anonymizer.sh panic-stop
	macbook-anonymizer.sh status
	macbook-anonymizer.sh test
	macbook-anonymizer.sh self-test
	macbook-anonymizer.sh privacy-report
	macbook-anonymizer.sh tor-env
	macbook-anonymizer.sh cloak-hostname [label]
	macbook-anonymizer.sh restore-hostname
	macbook-anonymizer.sh newnym
	macbook-anonymizer.sh checklist
	macbook-anonymizer.sh safe-apps
	macbook-anonymizer.sh launch-safe-app <profile>
	macbook-anonymizer.sh open-tor-browser
	macbook-anonymizer.sh validate

Commands:
	install  Install required dependencies with Homebrew (tor, curl, torsocks).
	doctor   Check macOS support, dependencies, Tor reachability, and proxy risk areas.
	start    Start tor, snapshot existing proxy config, disable proxy auto-config, clear bypasses,
	         and route macOS traffic through Tor SOCKS proxy where apps honor system proxy settings.
	stop     Restore previous proxy settings and stop tor service.
	panic-stop
	         Force a fast rollback: disable active proxy paths on all services, restore saved state when
	         available, and stop tor immediately.
	status   Show tor and system proxy state.
	test     Compare direct IP vs Tor-routed IP and query the Tor Project API.
	self-test
	         Run a guided verification pass that starts Tor routing, checks Tor/IP behavior,
	         confirms state capture, and restores settings before exiting.
	privacy-report
	         Inspect local host identity values and highlight obvious privacy risks.
	tor-env  Print environment variables for proxy-aware apps that can be pointed at Tor.
	cloak-hostname [label]
	         Save current host identity values and replace them with a generic hostname label.
	restore-hostname
	         Restore saved host identity values after cloak-hostname.
	newnym   Ask Tor for a fresh circuit (best effort).
	checklist
	         Print a leak-risk checklist for anonymous sessions.
	safe-apps
	         List curated app profiles that are safer to use during an anonymous session.
	launch-safe-app <profile>
	         Launch one of the curated safer app profiles by name.
	open-tor-browser
	         Launch Tor Browser from common macOS install paths and print session safety reminders.
	validate  Run lightweight static validation checks for this script.

Important:
	No tool can guarantee perfect anonymity. Browser fingerprinting, account logins,
	malicious endpoints, and OPSEC mistakes can still deanonymize you.
EOF
}

require_macos() {
	if [[ "$(uname -s)" != "Darwin" ]]; then
		echo "This tool is for macOS only."
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

require_privileged_access() {
	if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
		return 0
	fi
	if command -v sudo >/dev/null 2>&1; then
		sudo -v
		return 0
	fi
	echo "This command requires administrator privileges and sudo is not available."
	exit 1
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

generate_default_hostname_label() {
	printf 'anon-mac-%s' "$(date +%Y%m%d%H%M%S)"
}

sanitize_hostname_label() {
	printf '%s' "$1" | tr -cd '[:alnum:]-' | sed 's/--*/-/g; s/^-//; s/-$//'
}

list_services() {
	networksetup -listallnetworkservices | sed '1d' | sed 's/^\*//'
}

open_app_path() {
	local app_path="$1"
	open -a "$app_path"
}

list_app_search_roots() {
	local roots="${MACBOOK_ANONYMIZER_APP_SEARCH_ROOTS:-$APP_SEARCH_ROOTS_DEFAULT}"
	printf '%s' "$roots" | tr ':' '\n'
}

find_app_in_roots() {
	local relative_path="$1"
	local root
	while IFS= read -r root; do
		[[ -n "$root" ]] || continue
		if [[ -d "$root/$relative_path" ]]; then
			echo "$root/$relative_path"
			return 0
		fi
	done < <(list_app_search_roots)
	return 1
}

print_session_checklist() {
	echo "Leak-risk checklist:"
	echo "- Do not log into personal email, cloud, or social accounts."
	echo "- Prefer Tor Browser for any web activity."
	echo "- Keep the anonymous session separate from your normal browser session."
	echo "- Avoid opening personal files or documents during the session."
	echo "- Disable or avoid apps with background sync, messaging, or cloud uploads."
	echo "- Do not install extra browser extensions or helper apps."
	echo "- Avoid resizing Tor Browser windows or changing default appearance."
	echo "- Treat downloads as risky; open them only in isolated workflows."
	echo "- Stop the session and restore normal networking when finished."
}

list_safe_app_profiles() {
	cat <<'EOF'
Available safer app profiles:
- tor-browser      Preferred web browser for anonymous sessions.
- terminal         Local shell only; useful for status checks and local work.
- textedit         Local text editing with no network requirement.
- preview          Local file viewing with no network requirement.
- activity-monitor Local process inspection.
EOF
}

resolve_safe_app_path() {
	local profile="$1"
	case "$profile" in
		tor-browser)
			if find_app_in_roots "Tor Browser.app" || find_app_in_roots "Tor Browser/Tor Browser.app"; then
				return 0
			fi
			return 1
			;;
		terminal)
			if find_app_in_roots "Utilities/Terminal.app" || find_app_in_roots "Terminal.app"; then
				return 0
			fi
			return 1
			;;
		textedit)
			if find_app_in_roots "TextEdit.app"; then
				return 0
			fi
			return 1
			;;
		preview)
			if find_app_in_roots "Preview.app"; then
				return 0
			fi
			return 1
			;;
		activity-monitor)
			if find_app_in_roots "Utilities/Activity Monitor.app" || find_app_in_roots "Activity Monitor.app"; then
				return 0
			fi
			return 1
			;;
		*)
			return 1
			;;
	esac
}

print_safe_app_profile_note() {
	local profile="$1"
	case "$profile" in
		tor-browser)
			echo "Profile note: use this for web sessions; avoid personal logins, resizing, and extensions."
			;;
		terminal)
			echo "Profile note: local shell only; avoid tools that make direct outbound connections unless intentional."
			;;
		textedit)
			echo "Profile note: safer for local notes than cloud-synced editors."
			;;
		preview)
			echo "Profile note: local file viewing only; avoid opening downloaded files you do not trust."
			;;
		activity-monitor)
			echo "Profile note: useful to inspect background processes during an anonymous session."
			;;
	esac
}

scutil_get_value() {
	local key="$1"
	scutil --get "$key" 2>/dev/null || true
}

save_identity_state() {
	ensure_state_dir
	printf 'ComputerName\t%s\n' "$(scutil_get_value ComputerName)" > "$IDENTITY_STATE_FILE"
	printf 'LocalHostName\t%s\n' "$(scutil_get_value LocalHostName)" >> "$IDENTITY_STATE_FILE"
	printf 'HostName\t%s\n' "$(scutil_get_value HostName)" >> "$IDENTITY_STATE_FILE"
	chmod 600 "$IDENTITY_STATE_FILE" 2>/dev/null || true
}

read_identity_state_field() {
	local key="$1"
	awk -F'\t' -v wanted="$key" '$1==wanted {print $2}' "$IDENTITY_STATE_FILE" 2>/dev/null || true
}

restore_identity_state() {
	if [[ ! -f "$IDENTITY_STATE_FILE" ]]; then
		echo "No saved hostname state found."
		return 1
	fi
	local computer_name local_host_name host_name
	computer_name="$(read_identity_state_field ComputerName)"
	local_host_name="$(read_identity_state_field LocalHostName)"
	host_name="$(read_identity_state_field HostName)"
	[[ -n "$computer_name" ]] && run_privileged scutil --set ComputerName "$computer_name"
	[[ -n "$local_host_name" ]] && run_privileged scutil --set LocalHostName "$local_host_name"
	[[ -n "$host_name" ]] && run_privileged scutil --set HostName "$host_name"
	return 0
}

set_identity_values() {
	local label="$1"
	run_privileged scutil --set ComputerName "$label"
	run_privileged scutil --set LocalHostName "$label"
	run_privileged scutil --set HostName "$label"
}

identifier_looks_personal() {
	local value="$1"
	local user_name="${USER:-}"
	if [[ -z "$value" ]]; then
		return 1
	fi
	if [[ -n "$user_name" && "$value" == *"$user_name"* ]]; then
		return 0
	fi
	if [[ "$value" == *" "* || "$value" == *"@"* ]]; then
		return 0
	fi
	return 1
}

read_kv_field() {
	local subcommand="$1"
	local service="$2"
	local field="$3"
	networksetup "$subcommand" "$service" | awk -F': ' -v k="$field" '$1==k {print $2}'
}

read_socks_field() {
	read_kv_field -getsocksfirewallproxy "$1" "$2"
}

read_web_field() {
	read_kv_field -getwebproxy "$1" "$2"
}

read_secure_web_field() {
	read_kv_field -getsecurewebproxy "$1" "$2"
}

read_auto_proxy_field() {
	read_kv_field -getautoproxyurl "$1" "$2"
}

read_auto_discovery_state() {
	networksetup -getproxyautodiscovery "$1" | awk -F': ' 'NF > 1 {print $2}'
}

read_bypass_domains() {
	local service="$1"
	local output
	output="$(networksetup -getproxybypassdomains "$service")"
	if printf '%s\n' "$output" | grep -qi "aren't any bypass domains"; then
		echo ""
		return
	fi
	printf '%s\n' "$output" | tail -n +2 | awk 'NF {print}' | paste -sd'|' -
}

normalize_yes_no_state() {
	case "$1" in
		Yes|On|on|yes|true) echo "on" ;;
		*) echo "off" ;;
	esac
}

snapshot_proxy_state() {
	ensure_state_dir
	: > "$STATE_FILE"
	chmod 600 "$STATE_FILE" 2>/dev/null || true
	while IFS= read -r service; do
		[[ -n "$service" ]] || continue
		local socks_enabled socks_server socks_port
		local web_enabled web_server web_port
		local secure_enabled secure_server secure_port
		local auto_proxy_enabled auto_proxy_url autodiscovery_enabled bypass_domains
		socks_enabled="$(read_socks_field "$service" "Enabled")"
		socks_server="$(read_socks_field "$service" "Server")"
		socks_port="$(read_socks_field "$service" "Port")"
		web_enabled="$(read_web_field "$service" "Enabled")"
		web_server="$(read_web_field "$service" "Server")"
		web_port="$(read_web_field "$service" "Port")"
		secure_enabled="$(read_secure_web_field "$service" "Enabled")"
		secure_server="$(read_secure_web_field "$service" "Server")"
		secure_port="$(read_secure_web_field "$service" "Port")"
		auto_proxy_enabled="$(read_auto_proxy_field "$service" "Enabled")"
		auto_proxy_url="$(read_auto_proxy_field "$service" "URL")"
		autodiscovery_enabled="$(read_auto_discovery_state "$service")"
		bypass_domains="$(read_bypass_domains "$service")"
		printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
			"$service" \
			"$socks_enabled" "$socks_server" "$socks_port" \
			"$web_enabled" "$web_server" "$web_port" \
			"$secure_enabled" "$secure_server" "$secure_port" \
			"$auto_proxy_enabled" "$auto_proxy_url" \
			"$autodiscovery_enabled|$bypass_domains" >> "$STATE_FILE"
	 done < <(list_services)
}

restore_proxy_state() {
	if [[ ! -f "$STATE_FILE" ]]; then
		echo "No saved proxy state found at: $STATE_FILE"
		echo "Safety guard: leaving existing proxy settings unchanged."
		return 1
	fi

	while IFS=$'\t' read -r service \
		socks_enabled socks_server socks_port \
		web_enabled web_server web_port \
		secure_enabled secure_server secure_port \
		auto_proxy_enabled auto_proxy_url extra; do
		[[ -n "$service" ]] || continue
		local autodiscovery_enabled bypass_domains
		autodiscovery_enabled="${extra%%|*}"
		bypass_domains="${extra#*|}"

		if [[ -n "$socks_server" && -n "$socks_port" && "$socks_port" != "0" ]]; then
			networksetup -setsocksfirewallproxy "$service" "$socks_server" "$socks_port" >/dev/null
		fi
		networksetup -setsocksfirewallproxystate "$service" "$(normalize_yes_no_state "$socks_enabled")" >/dev/null

		if [[ -n "$web_server" && -n "$web_port" && "$web_port" != "0" ]]; then
			networksetup -setwebproxy "$service" "$web_server" "$web_port" >/dev/null
		fi
		networksetup -setwebproxystate "$service" "$(normalize_yes_no_state "$web_enabled")" >/dev/null

		if [[ -n "$secure_server" && -n "$secure_port" && "$secure_port" != "0" ]]; then
			networksetup -setsecurewebproxy "$service" "$secure_server" "$secure_port" >/dev/null
		fi
		networksetup -setsecurewebproxystate "$service" "$(normalize_yes_no_state "$secure_enabled")" >/dev/null

		if [[ -n "$auto_proxy_url" ]]; then
			networksetup -setautoproxyurl "$service" "$auto_proxy_url" >/dev/null
		fi
		networksetup -setautoproxystate "$service" "$(normalize_yes_no_state "$auto_proxy_enabled")" >/dev/null
		networksetup -setproxyautodiscovery "$service" "$(normalize_yes_no_state "$autodiscovery_enabled")" >/dev/null

		if [[ -n "$bypass_domains" && "$bypass_domains" != "$extra" ]]; then
			IFS='|' read -r -a bypass_array <<< "$bypass_domains"
			networksetup -setproxybypassdomains "$service" "${bypass_array[@]}" >/dev/null
		else
			networksetup -setproxybypassdomains "$service" Empty >/dev/null
		fi
	 done < "$STATE_FILE"
}

start_tor() {
	if ! brew services list | awk '{print $1" "$2}' | grep -q '^tor started$'; then
		brew services start tor >/dev/null
	fi
}

stop_tor() {
	if brew services list | awk '{print $1" "$2}' | grep -q '^tor started$'; then
		brew services stop tor >/dev/null
	fi
}

disable_all_proxy_paths() {
	while IFS= read -r service; do
		[[ -n "$service" ]] || continue
		networksetup -setsocksfirewallproxystate "$service" off >/dev/null || true
		networksetup -setwebproxystate "$service" off >/dev/null || true
		networksetup -setsecurewebproxystate "$service" off >/dev/null || true
		networksetup -setautoproxystate "$service" off >/dev/null || true
		networksetup -setproxyautodiscovery "$service" off >/dev/null || true
		networksetup -setproxybypassdomains "$service" Empty >/dev/null || true
	done < <(list_services)
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

route_all_services_through_tor() {
	while IFS= read -r service; do
		[[ -n "$service" ]] || continue
		networksetup -setautoproxystate "$service" off >/dev/null
		networksetup -setproxyautodiscovery "$service" off >/dev/null
		networksetup -setwebproxystate "$service" off >/dev/null
		networksetup -setsecurewebproxystate "$service" off >/dev/null
		networksetup -setproxybypassdomains "$service" Empty >/dev/null
		networksetup -setsocksfirewallproxy "$service" "$TOR_SOCKS_HOST" "$TOR_SOCKS_PORT" >/dev/null
		networksetup -setsocksfirewallproxystate "$service" on >/dev/null
	 done < <(list_services)
}

print_tor_api_status() {
	local tor_json is_tor tor_ip
	tor_json="$(get_tor_api_json)"
	is_tor="$(get_tor_api_is_tor "$tor_json")"
	tor_ip="$(get_tor_api_ip "$tor_json")"
	echo "Tor API says IsTor=${is_tor:-unknown}, IP=${tor_ip:-unavailable}"
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

cmd_install() {
	require_macos
	if ! command -v brew >/dev/null 2>&1; then
		echo "Homebrew is required. Install from https://brew.sh first."
		exit 1
	fi
	brew install tor curl torsocks >/dev/null
	echo "Dependencies installed."
}

cmd_doctor() {
	require_macos
	echo "Running diagnostics for $TOOL_NAME..."
	for cmd in brew curl nc networksetup; do
		if command -v "$cmd" >/dev/null 2>&1; then
			echo "[ok] $cmd"
		else
			echo "[missing] $cmd"
		fi
	done
	if command -v brew >/dev/null 2>&1; then
		for formula in tor torsocks; do
			if brew list --formula "$formula" >/dev/null 2>&1; then
				echo "[ok] brew formula installed: $formula"
			else
				echo "[missing] brew formula: $formula"
			fi
		done
	fi
	if nc -z "$TOR_SOCKS_HOST" "$TOR_SOCKS_PORT" >/dev/null 2>&1; then
		echo "[ok] Tor SOCKS port reachable at ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}"
	else
		echo "[warn] Tor SOCKS port not reachable at ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}"
	fi
	while IFS= read -r service; do
		[[ -n "$service" ]] || continue
		echo "[service] $service"
		echo "  socks: $(read_socks_field "$service" "Enabled") $(read_socks_field "$service" "Server"):$(read_socks_field "$service" "Port")"
		echo "  web:   $(read_web_field "$service" "Enabled") $(read_web_field "$service" "Server"):$(read_web_field "$service" "Port")"
		echo "  https: $(read_secure_web_field "$service" "Enabled") $(read_secure_web_field "$service" "Server"):$(read_secure_web_field "$service" "Port")"
		echo "  pac:   $(read_auto_proxy_field "$service" "Enabled") $(read_auto_proxy_field "$service" "URL")"
		echo "  pad:   $(read_auto_discovery_state "$service")"
		if [[ -n "$(read_bypass_domains "$service")" ]]; then
			echo "  bypass domains are set"
		else
			echo "  bypass domains are empty"
		fi
	done < <(list_services)
}

cmd_start() {
	require_macos
	require_cmd networksetup
	require_cmd brew
	require_cmd nc

	local original_tor_state=""
	local start_succeeded=0
	original_tor_state="$(brew services list | awk '$1=="tor" {print $2; exit}')"

	rollback_on_failed_start() {
		if [[ "$start_succeeded" -eq 1 ]]; then
			return 0
		fi
		echo "Start failed. Attempting safety rollback..."
		restore_proxy_state >/dev/null 2>&1 || true
		if [[ "$original_tor_state" != "started" ]]; then
			stop_tor >/dev/null 2>&1 || true
		fi
	}
	trap rollback_on_failed_start RETURN

	echo "Starting $TOOL_NAME..."
	snapshot_proxy_state
	start_tor
	wait_for_tor
	route_all_services_through_tor
	start_succeeded=1
	trap - RETURN

	echo "Tor SOCKS routing enabled on all macOS network services."
	echo "Proxy auto-config, auto-discovery, and bypass domains were disabled while active."
	echo "Run: $0 status"
	echo "Run: $0 test"
}

cmd_stop() {
	require_macos
	require_cmd networksetup
	require_cmd brew

	echo "Stopping $TOOL_NAME..."
	if restore_proxy_state; then
		echo "Proxy settings restored from saved state."
	else
		echo "Warning: no saved state available; proxy settings were left unchanged."
	fi
	stop_tor
	echo "Tor service stopped."
}

cmd_panic_stop() {
	require_macos
	require_cmd networksetup

	echo "Panic stop: disabling proxy paths immediately..."
	disable_all_proxy_paths
	if [[ -f "$STATE_FILE" ]]; then
		echo "Restoring saved proxy state..."
		restore_proxy_state
	fi
	if command -v brew >/dev/null 2>&1; then
		stop_tor || true
	fi
	if pgrep -x tor >/dev/null 2>&1; then
		pkill -TERM tor || true
	fi
	echo "Panic stop complete."
}

cmd_status() {
	require_macos
	require_cmd networksetup
	require_cmd brew

	echo "Tor service status:"
	brew services list | awk 'NR==1 || $1=="tor"'
	echo
	echo "Proxy status per service:"
	while IFS= read -r service; do
		[[ -n "$service" ]] || continue
		echo "- $service"
		echo "  socks: enabled=$(read_socks_field "$service" "Enabled"), server=$(read_socks_field "$service" "Server"), port=$(read_socks_field "$service" "Port")"
		echo "  web:   enabled=$(read_web_field "$service" "Enabled"), server=$(read_web_field "$service" "Server"), port=$(read_web_field "$service" "Port")"
		echo "  https: enabled=$(read_secure_web_field "$service" "Enabled"), server=$(read_secure_web_field "$service" "Server"), port=$(read_secure_web_field "$service" "Port")"
		echo "  pac:   enabled=$(read_auto_proxy_field "$service" "Enabled"), url=$(read_auto_proxy_field "$service" "URL")"
		echo "  pad:   state=$(read_auto_discovery_state "$service")"
		local bypass
		bypass="$(read_bypass_domains "$service")"
		echo "  bypass domains=${bypass:-none}"
	 done < <(list_services)
	if [[ -f "$STATE_FILE" ]]; then
		echo
		echo "Saved state file: $STATE_FILE"
	fi
}

cmd_test() {
	require_macos
	require_cmd curl

	local direct_ip tor_ip
	direct_ip="$(get_direct_ip)"
	tor_ip="$(get_tor_ip)"

	echo "Direct IP: ${direct_ip:-unavailable}"
	echo "Tor IP:    ${tor_ip:-unavailable}"
	print_tor_api_status

	if [[ -n "$direct_ip" && -n "$tor_ip" && "$direct_ip" != "$tor_ip" ]]; then
		echo "Looks good: Tor exit IP differs from direct IP."
	else
		echo "Warning: Unable to confirm Tor routing difference."
	fi
}

cmd_self_test() {
	require_macos
	require_cmd curl
	require_cmd networksetup
	require_cmd brew
	require_cmd nc

	local passed=0
	local failed=0
	local started_here=0
	local direct_ip tor_ip tor_json is_tor tor_api_ip
	local original_tor_state
	original_tor_state="$(brew services list | awk '$1=="tor" {print $2; exit}')"

	restore_self_test_state() {
		if [[ "$started_here" -eq 1 ]]; then
			restore_proxy_state || true
			if [[ "$original_tor_state" == "started" ]]; then
				start_tor || true
			else
				stop_tor || true
			fi
		fi
	}

	trap restore_self_test_state EXIT

	report_result() {
		local ok="$1"
		local message="$2"
		if [[ "$ok" == "ok" ]]; then
			printf '[ok] %s\n' "$message"
			passed=$((passed + 1))
		else
			printf '[fail] %s\n' "$message"
			failed=$((failed + 1))
		fi
	}

	echo "Running self-test for $TOOL_NAME..."
	snapshot_proxy_state
	start_tor
	started_here=1
	if wait_for_tor; then
		report_result ok "Tor SOCKS port is reachable"
	else
		report_result fail "Tor SOCKS port did not become reachable"
	fi

	route_all_services_through_tor
	if [[ -f "$STATE_FILE" ]]; then
		report_result ok "Proxy state snapshot was created"
	else
		report_result fail "Proxy state snapshot file is missing"
	fi

	direct_ip="$(get_direct_ip)"
	tor_ip="$(get_tor_ip)"
	tor_json="$(get_tor_api_json)"
	is_tor="$(get_tor_api_is_tor "$tor_json")"
	tor_api_ip="$(get_tor_api_ip "$tor_json")"

	echo "Direct IP: ${direct_ip:-unavailable}"
	echo "Tor IP:    ${tor_ip:-unavailable}"
	echo "Tor API:   IsTor=${is_tor:-unknown} IP=${tor_api_ip:-unavailable}"

	if [[ -n "$direct_ip" && -n "$tor_ip" && "$direct_ip" != "$tor_ip" ]]; then
		report_result ok "Tor exit IP differs from direct IP"
	else
		report_result fail "Tor exit IP does not differ from direct IP"
	fi

	if [[ "$is_tor" == "true" ]]; then
		report_result ok "Tor Project API confirms Tor routing"
	else
		report_result fail "Tor Project API did not confirm Tor routing"
	fi

	echo "Self-test summary: passed=${passed} failed=${failed}"
	if [[ "$failed" -gt 0 ]]; then
		return 1
	fi
}

cmd_newnym() {
	require_macos
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
	require_macos
	require_cmd scutil
	local computer_name local_host_name host_name
	computer_name="$(scutil_get_value ComputerName)"
	local_host_name="$(scutil_get_value LocalHostName)"
	host_name="$(scutil_get_value HostName)"
	echo "Host identity report:"
	echo "- ComputerName: ${computer_name:-unset}"
	echo "- LocalHostName: ${local_host_name:-unset}"
	echo "- HostName: ${host_name:-unset}"
	if identifier_looks_personal "$computer_name" || identifier_looks_personal "$local_host_name" || identifier_looks_personal "$host_name"; then
		echo "Warning: one or more host identity values look personal or unique."
		echo "Consider: $0 cloak-hostname anon-mac"
	else
		echo "No obvious personal identifiers were detected in host identity values."
	fi
	if [[ -f "$IDENTITY_STATE_FILE" ]]; then
		echo "Saved hostname state file: $IDENTITY_STATE_FILE"
	fi
}

cmd_tor_env() {
	require_macos
	cat <<EOF
Export these for proxy-aware CLI tools and apps:
export ALL_PROXY=socks5h://${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}
export HTTP_PROXY=socks5h://${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}
export HTTPS_PROXY=socks5h://${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}
export NO_PROXY=localhost,127.0.0.1,::1

Example:
ALL_PROXY=socks5h://${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT} curl https://check.torproject.org/api/ip

If torsocks is installed:
torsocks curl https://check.torproject.org/api/ip
EOF
}

cmd_cloak_hostname() {
	require_macos
	require_cmd scutil
	require_privileged_access
	local raw_label="${1:-$(generate_default_hostname_label)}"
	local sanitized_label
	sanitized_label="$(sanitize_hostname_label "$raw_label")"
	if [[ -z "$sanitized_label" ]]; then
		echo "Unable to derive a valid hostname label from: $raw_label"
		exit 1
	fi
	save_identity_state
	if ! set_identity_values "$sanitized_label"; then
		echo "Hostname cloaking failed. Attempting rollback..."
		restore_identity_state || true
		exit 1
	fi
	echo "Host identity values were changed to: $sanitized_label"
	echo "Restore with: $0 restore-hostname"
}

cmd_restore_hostname() {
	require_macos
	require_cmd scutil
	require_privileged_access
	if restore_identity_state; then
		echo "Host identity values restored from saved state."
	else
		exit 1
	fi
}

cmd_checklist() {
	require_macos
	print_session_checklist
}

cmd_safe_apps() {
	require_macos
	list_safe_app_profiles
}

cmd_launch_safe_app() {
	require_macos
	local profile="${1:-}"
	local app_path=""
	if [[ -z "$profile" ]]; then
		echo "Usage: $0 launch-safe-app <profile>"
		list_safe_app_profiles
		exit 1
	fi
	if ! app_path="$(resolve_safe_app_path "$profile")"; then
		echo "Unknown or unavailable safe app profile: $profile"
		list_safe_app_profiles
		exit 1
	fi
	echo "Launching safe app profile: $profile"
	print_safe_app_profile_note "$profile"
	if [[ "$profile" == "tor-browser" ]]; then
		print_session_checklist
	fi
	open_app_path "$app_path"
}

cmd_open_tor_browser() {
	require_macos
	cmd_launch_safe_app tor-browser
}

cmd_validate() {
	require_cmd awk
	require_cmd sed
	require_cmd paste
	require_cmd networksetup
	require_cmd scutil
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
		panic-stop) cmd_panic_stop ;;
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
