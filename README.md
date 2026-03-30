# MacBook Anonymizer

A macOS anonymity helper that routes network traffic through Tor using stricter macOS proxy hardening.

## Fast Install for Mac Users

The GitHub repo explains install right here at the top because most users will land on this page first.

## GitHub Quick Start (Copy/Paste)

```bash
curl -fsSL https://raw.githubusercontent.com/Evren12346/macbook-anonymizer/main/install-mac.sh | bash
```

This installs everything and auto-opens the menu launcher.

If you prefer no auto-open:

```bash
MACBOOK_ANONYMIZER_AUTO_LAUNCH=0 curl -fsSL https://raw.githubusercontent.com/Evren12346/macbook-anonymizer/main/install-from-github.sh | bash
```

Manual launch (any time):

```bash
~/Applications/MacBook\ Anonymizer/MacBook\ Anonymizer.command
```

## Fast Install for Ubuntu Users

```bash
curl -fsSL https://raw.githubusercontent.com/Evren12346/macbook-anonymizer/main/install-ubuntu.sh | bash
```

If you prefer no auto-open:

```bash
MACBOOK_ANONYMIZER_AUTO_LAUNCH=0 curl -fsSL https://raw.githubusercontent.com/Evren12346/macbook-anonymizer/main/install-ubuntu-from-github.sh | bash
```

Manual launch (any time):

```bash
~/Applications/MacBook\ Anonymizer\ Ubuntu/MacBook\ Anonymizer\ Ubuntu.command
```

## Direct ZIP Download

- Latest release ZIP (`v1.2.0`): https://github.com/Evren12346/macbook-anonymizer/archive/refs/tags/v1.2.0.zip
- Latest main branch ZIP: https://github.com/Evren12346/macbook-anonymizer/archive/refs/heads/main.zip

### Option 1: GitHub ZIP download

1. Download the repository ZIP from GitHub and unzip it.
2. Open the unzipped folder.
3. Double-click `Install MacBook Anonymizer.command`.
4. If macOS blocks the launcher the first time, right-click it and choose `Open`.
5. After install finishes, double-click `MacBook Anonymizer.command` to use the menu.

### Option 2: One-line Terminal install from GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/Evren12346/macbook-anonymizer/main/install-mac.sh | bash
```

This installs the project into `~/Applications/MacBook Anonymizer`, installs dependencies, prepares the launchers, and opens the menu automatically.

The GitHub installer now prefers the latest GitHub release tag when one exists, falls back to `main` if needed, and creates a Launchpad-ready app bundle in `~/Applications`.

### Option 3: One-line Ubuntu install from GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/Evren12346/macbook-anonymizer/main/install-ubuntu.sh | bash
```

This installs the Ubuntu version into `~/Applications/MacBook Anonymizer Ubuntu`, installs Linux dependencies, and opens the Ubuntu menu launcher.

### Option 4: Git clone

```bash
git clone https://github.com/Evren12346/macbook-anonymizer.git
cd macbook-anonymizer
./install.sh
```

## First Run

After installing:

1. Run `doctor` to verify macOS tooling and Tor dependencies.
2. Run `self-test` once to confirm Tor routing and rollback behavior.
3. Use `start` when you actually want an anonymized session.
4. Use `stop` when you are done.

The easiest way to do this is the included menu launcher:

```bash
./MacBook\ Anonymizer.command
```

The installer also tries to create:

- `~/Applications/MacBook Anonymizer.app` for Finder and Launchpad use
- `~/Applications/MacBook Anonymizer` as the installed project folder for the GitHub installer path

The repo also includes a real-Mac smoke test runner and a packaging script for signed/notarized release builds.

If macOS blocks a downloaded launcher or app on first use, right-click it and choose `Open` once.

## What it does

- Installs Tor tooling with Homebrew (`install` command)
- Runs a local diagnostics pass (`doctor` command)
- Reports host identity values that may leak personal information (`privacy-report`)
- Prints Tor proxy environment exports for proxy-aware apps (`tor-env`)
- Starts Tor as a background service (`start` command)
- Saves current macOS SOCKS, HTTP, HTTPS, auto-proxy, auto-discovery, and bypass-domain state
- Disables proxy auto-config and bypass domains while active
- Enables SOCKS proxy routing to Tor (`127.0.0.1:9050`) on all services
- Tests direct IP vs Tor IP and checks the Tor Project API (`test` command)
- Adds a one-shot verification flow (`self-test` command)
- Adds a fast rollback path (`panic-stop` command)
- Can temporarily replace local host identity values with a generic label (`cloak-hostname` / `restore-hostname`)
- Prints a built-in leak-risk checklist (`checklist` command)
- Lists and launches curated safer app profiles (`safe-apps` and `launch-safe-app`)
- Can launch Tor Browser with safety reminders (`open-tor-browser` command)
- Restores your prior proxy settings and stops Tor (`stop` command)

## Native macOS App (SwiftUI)

For a beautiful, native macOS experience with a modern GUI:

```bash
cd macos-app
./build.sh
# Or open in Xcode:
open Package.swift
```

The native app includes:
- **Beautiful Dashboard**: Modern dark-themed interface
- **One-Click Controls**: Start/Stop Tor easily
- **Quick Actions**: Diagnostics, testing, privacy reports
- **Live Output**: Real-time command output display
- **System Integration**: Dock icon, proper macOS app lifecycle

See [macos-app/README.md](macos-app/README.md) for detailed build and installation instructions.

## Command-Line Files

- Main script: `bin/macbook_anonymizer.sh`
- Ubuntu script: `bin/macbook_anonymizer_ubuntu.sh`
- ZIP-friendly installer: `Install MacBook Anonymizer.command`
- GitHub installer: `install-from-github.sh`
- Ubuntu GitHub installer: `install-ubuntu-from-github.sh`
- Ubuntu one-line wrapper: `install-ubuntu.sh`
- Standard installer: `install.sh`
- Menu launcher: `MacBook Anonymizer.command`
- Ubuntu menu launcher: `MacBook Anonymizer Ubuntu.command`
- macOS app builder: `build_macos_app.sh`
- Icon generator: `generate_macos_icon.sh`
- Release packager: `package_macos_release.sh`
- Real-Mac smoke test: `real_macos_smoke_test.sh`
- Real-Mac smoke test guide: `REAL_MAC_SMOKE_TEST.md`
- Icon source: `assets/macbook_anonymizer-icon.svg`
- Local state snapshot: `~/.macbook_anonymizer/proxy_state.tsv`

## Requirements

- macOS: Homebrew + admin privileges may be required for `cloak-hostname` and `restore-hostname`
- Ubuntu: `apt-get` + admin privileges for dependency install and hostname operations

## Usage

```bash
cd macbook-anonymizer

# One-time setup
./install.sh

# Open the interactive menu
./MacBook\ Anonymizer.command

# Or launch the installed app bundle if it was created in ~/Applications (macOS)
open ~/Applications/MacBook\ Anonymizer.app

# Diagnostics
./bin/macbook_anonymizer.sh doctor

# Review local host identity exposure
./bin/macbook_anonymizer.sh privacy-report

# Print Tor proxy environment variables for proxy-aware apps
./bin/macbook_anonymizer.sh tor-env

# Replace local hostname values with a generic label
./bin/macbook_anonymizer.sh cloak-hostname anon-mac

# Enable Tor routing
./bin/macbook_anonymizer.sh start

# Check status and verify
./bin/macbook_anonymizer.sh status
./bin/macbook_anonymizer.sh test

# Run the full guided verification flow
./bin/macbook_anonymizer.sh self-test

# Ask Tor for a new circuit
./bin/macbook_anonymizer.sh newnym

# Print leak-risk checklist
./bin/macbook_anonymizer.sh checklist

# List and launch curated safer app profiles
./bin/macbook_anonymizer.sh safe-apps
./bin/macbook_anonymizer.sh launch-safe-app tor-browser

# Launch Tor Browser with reminders
./bin/macbook_anonymizer.sh open-tor-browser

# Restore normal state
./bin/macbook_anonymizer.sh stop

# Fast emergency rollback
./bin/macbook_anonymizer.sh panic-stop

# Non-interactive emergency rollback (CI/automation)
./bin/macbook_anonymizer.sh panic-stop --force

# Restore saved hostname values
./bin/macbook_anonymizer.sh restore-hostname

# Optional .app wrapper build on macOS
./build_macos_app.sh

# Optional packaging flow for signed/notarized release builds
./package_macos_release.sh

# Real-Mac validation run
./real_macos_smoke_test.sh

# Ubuntu menu launcher
./MacBook\ Anonymizer\ Ubuntu.command

# Ubuntu diagnostics
./bin/macbook_anonymizer_ubuntu.sh doctor

# Ubuntu start/stop flow
./bin/macbook_anonymizer_ubuntu.sh start
./bin/macbook_anonymizer_ubuntu.sh test
./bin/macbook_anonymizer_ubuntu.sh stop
```

## Everyday Use

- Double-click `MacBook Anonymizer.command` for the menu-driven version.
- On Ubuntu, launch `MacBook Anonymizer Ubuntu.command` for the matching menu-driven version.
- If the installer created `~/Applications/MacBook Anonymizer.app`, you can launch it from Launchpad like a normal Mac app.
- Run `./bin/macbook_anonymizer.sh start` before an anonymous session.
- Run `./bin/macbook_anonymizer.sh stop` when the session ends.
- Use `panic-stop` if you want the fastest available rollback.

## Ubuntu Version Notes

- The Ubuntu command set mirrors the macOS flow and menu labels as closely as possible.
- Desktop proxy routing uses GNOME `gsettings` when available; on other desktop environments, use `tor-env` with proxy-aware apps.
- Tor startup prefers system services and falls back to a local Tor daemon when needed.

## Packaging and Release Builds

For a distributable macOS app bundle and zip:

```bash
./package_macos_release.sh
```

Optional signing and notarization environment variables:

- `APPLE_SIGN_IDENTITY` for `codesign`
- `APPLE_NOTARY_PROFILE` for `xcrun notarytool` keychain-profile based notarization
- or `APPLE_ID`, `APPLE_TEAM_ID`, and `APPLE_APP_SPECIFIC_PASSWORD` for direct notarization credentials

The packaging script builds the app, applies the custom icon if available, optionally signs it, zips it, writes a SHA-256 checksum, and notarizes/staples when credentials are provided.

## Real Mac Validation

This Linux workspace cannot execute the true macOS networking path directly, so the repo now includes a ready-to-run real-Mac validation path:

```bash
./real_macos_smoke_test.sh
```

See `REAL_MAC_SMOKE_TEST.md` for what it checks and what still needs manual confirmation.

## Practical anonymity hardening tips for macOS

- Use a dedicated browser profile for anonymous sessions only.
- Prefer Tor Browser for web sessions if you have it installed.
- Disable cloud account sync while anonymized.
- Do not log into personal accounts from the anonymous session.
- Disable location services for apps used during anonymized sessions.
- Keep macOS and browser fully updated.
- Prefer privacy-focused DNS and avoid unnecessary background apps.

## What the upgrade improves

- Restores more of your original macOS proxy state after shutdown.
- Clears proxy bypass domains while active to reduce accidental direct connections.
- Disables proxy auto-discovery and PAC settings while active to avoid conflicting proxy behavior.
- Adds a `doctor` command to catch missing dependencies and risky proxy settings early.
- Adds Tor Project API verification in `test`.
- Adds `self-test` to start the profile, verify routing, and restore settings in one command.
- Adds `panic-stop` for a faster emergency rollback path.
- Adds a host identity report, Tor env export helper, and reversible hostname cloaking.
- Adds a clearer leak-risk checklist and a curated safer-app launcher mode.
- Adds a macOS `.command` menu launcher and a `.app` builder script.
- Adds a Tor Browser launcher helper with session safety reminders.

## Important caveat

No software can guarantee complete anonymity. Browser fingerprinting, account logins, endpoint compromise, and behavior patterns can still reveal identity.

## Validation note

The command logic has been syntax-checked and exercised through mocked macOS command flows from this workspace, but final validation still needs to be run on a real Mac against actual `networksetup`, `scutil`, Tor, and Homebrew services.
