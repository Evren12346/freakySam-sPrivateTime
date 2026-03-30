#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer is for macOS only."
  exit 1
fi

curl -fsSL "https://raw.githubusercontent.com/Evren12346/macbook-anonymizer/main/install-from-github.sh" | bash
