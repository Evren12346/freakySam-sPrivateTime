# Freaky Sam's Private Time

A macOS anonymity helper that routes network traffic through Tor using stricter macOS proxy hardening.

## Fast Install for Mac Users

The GitHub repo explains install right here at the top because most users will land on this page first.

### Option 1: GitHub ZIP download

1. Download the repository ZIP from GitHub and unzip it.
2. Open the unzipped folder.
3. Double-click `Install Freaky Sams Private Time.command`.
4. If macOS blocks the launcher the first time, right-click it and choose `Open`.
5. After install finishes, double-click `Freaky Sams Private Time.command` to use the menu.

### Option 2: One-line Terminal install from GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/Evren12346/freakySam-sPrivateTime/main/install-from-github.sh | bash
```

This installs the project into `~/Applications/Freaky Sams Private Time`, installs dependencies, and prepares the launchers for you.

The GitHub installer now prefers the latest GitHub release tag when one exists, falls back to `main` if needed, and creates a Launchpad-ready app bundle in `~/Applications`.

### Option 3: Git clone

```bash
git clone https://github.com/Evren12346/freakySam-sPrivateTime.git
cd freakySam-sPrivateTime
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
./Freaky\ Sams\ Private\ Time.command
```

The installer also tries to create:

- `~/Applications/Freaky Sams Private Time.app` for Finder and Launchpad use
- `~/Applications/Freaky Sams Private Time` as the installed project folder for the GitHub installer path

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

## Files

- Main script: `bin/freaky-sams-private-time.sh`
- ZIP-friendly installer: `Install Freaky Sams Private Time.command`
- GitHub installer: `install-from-github.sh`
- Standard installer: `install.sh`
- Menu launcher: `Freaky Sams Private Time.command`
- macOS app builder: `build_macos_app.sh`
- Icon generator: `generate_macos_icon.sh`
- Release packager: `package_macos_release.sh`
- Real-Mac smoke test: `real_macos_smoke_test.sh`
- Real-Mac smoke test guide: `REAL_MAC_SMOKE_TEST.md`
- Icon source: `assets/freaky-sams-private-time-icon.svg`
- Local state snapshot: `~/.freaky-sams-private-time/proxy_state.tsv`

## Requirements

- macOS
- Homebrew
- Administrator privileges may be required for `cloak-hostname` and `restore-hostname`

## Usage

```bash
cd freakySam-sPrivateTime

# One-time setup
./install.sh

# Open the interactive menu
./Freaky\ Sams\ Private\ Time.command

# Or launch the installed app bundle if it was created in ~/Applications
open ~/Applications/Freaky\ Sams\ Private\ Time.app

# Diagnostics
./bin/freaky-sams-private-time.sh doctor

# Review local host identity exposure
./bin/freaky-sams-private-time.sh privacy-report

# Print Tor proxy environment variables for proxy-aware apps
./bin/freaky-sams-private-time.sh tor-env

# Replace local hostname values with a generic label
./bin/freaky-sams-private-time.sh cloak-hostname anon-mac

# Enable Tor routing
./bin/freaky-sams-private-time.sh start

# Check status and verify
./bin/freaky-sams-private-time.sh status
./bin/freaky-sams-private-time.sh test

# Run the full guided verification flow
./bin/freaky-sams-private-time.sh self-test

# Ask Tor for a new circuit
./bin/freaky-sams-private-time.sh newnym

# Print leak-risk checklist
./bin/freaky-sams-private-time.sh checklist

# List and launch curated safer app profiles
./bin/freaky-sams-private-time.sh safe-apps
./bin/freaky-sams-private-time.sh launch-safe-app tor-browser

# Launch Tor Browser with reminders
./bin/freaky-sams-private-time.sh open-tor-browser

# Restore normal state
./bin/freaky-sams-private-time.sh stop

# Fast emergency rollback
./bin/freaky-sams-private-time.sh panic-stop

# Restore saved hostname values
./bin/freaky-sams-private-time.sh restore-hostname

# Optional .app wrapper build on macOS
./build_macos_app.sh

# Optional packaging flow for signed/notarized release builds
./package_macos_release.sh

# Real-Mac validation run
./real_macos_smoke_test.sh
```

## Everyday Use

- Double-click `Freaky Sams Private Time.command` for the menu-driven version.
- If the installer created `~/Applications/Freaky Sams Private Time.app`, you can launch it from Launchpad like a normal Mac app.
- Run `./bin/freaky-sams-private-time.sh start` before an anonymous session.
- Run `./bin/freaky-sams-private-time.sh stop` when the session ends.
- Use `panic-stop` if you want the fastest available rollback.

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
