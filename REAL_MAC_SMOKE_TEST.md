# Real Mac Smoke Test

Use this on an actual Mac to validate the project against real `networksetup`, `scutil`, Homebrew, Tor, and Launch Services behavior.

## Quick Run

```bash
cd amazingSam-sPrivateTime
./real_macos_smoke_test.sh
```

The script will:

- run `doctor`
- run `privacy-report`
- list safe app profiles
- build the `.app` bundle and copy it into `~/Applications`
- run `self-test`
- run an explicit `start`, `status`, `test`, and `stop`
- write a timestamped log into `test_logs/`

## What to check manually after the script

- Confirm the app opens from `~/Applications/Amazing Sams Private Time.app`
- Confirm Tor Browser launch works if Tor Browser is installed
- Confirm system proxy settings are restored after `stop`
- Confirm Gatekeeper only needs a one-time `Open` flow if macOS prompts
- Confirm the log file shows a different Tor-routed IP than the direct IP

## Safety note

The script changes active macOS proxy settings during the test and then restores them on exit. Avoid running it during sensitive network activity.