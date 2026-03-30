#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This installer is for Linux/Ubuntu only."
  exit 1
fi

curl -fsSL "https://raw.githubusercontent.com/Evren12346/macbook-anonymizer/main/install-ubuntu-from-github.sh" | bash
