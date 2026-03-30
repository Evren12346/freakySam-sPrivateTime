#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="$SCRIPT_DIR/bin/macbook_anonymizer_ubuntu.sh"

chmod +x "$TOOL"

while true; do
  clear
  echo "macbook anonymizer (ubuntu)"
  echo
  echo "1. Install dependencies"
  echo "2. Doctor"
  echo "3. Privacy report"
  echo "4. Show Tor env exports"
  echo "5. Cloak hostname"
  echo "6. Restore hostname"
  echo "7. Start anonymity mode"
  echo "8. Status"
  echo "9. Test Tor routing"
  echo "10. Run self-test"
  echo "11. New Tor circuit"
  echo "12. Leak-risk checklist"
  echo "13. List safe apps"
  echo "14. Launch safe app"
  echo "15. Open Tor Browser"
  echo "16. Stop and restore"
  echo "17. Panic stop"
  echo "0. Exit"
  echo
  read -r -p "Choose an option: " choice
  echo

  case "$choice" in
    1) "$TOOL" install ;;
    2) "$TOOL" doctor ;;
    3) "$TOOL" privacy-report ;;
    4) "$TOOL" tor-env ;;
    5)
      read -r -p "Enter cloak label (blank for auto): " label
      if [[ -n "$label" ]]; then
        "$TOOL" cloak-hostname "$label"
      else
        "$TOOL" cloak-hostname
      fi
      ;;
    6) "$TOOL" restore-hostname ;;
    7) "$TOOL" start ;;
    8) "$TOOL" status ;;
    9) "$TOOL" test ;;
    10) "$TOOL" self-test ;;
    11) "$TOOL" newnym ;;
    12) "$TOOL" checklist ;;
    13) "$TOOL" safe-apps ;;
    14)
      "$TOOL" safe-apps
      echo
      read -r -p "Enter profile name: " profile
      "$TOOL" launch-safe-app "$profile"
      ;;
    15) "$TOOL" open-tor-browser ;;
    16) "$TOOL" stop ;;
    17) "$TOOL" panic-stop ;;
    0) exit 0 ;;
    *) echo "Invalid option." ;;
  esac

  echo
  read -r -p "Press Enter to continue..." _
done
