#!/usr/bin/env bash
set -euo pipefail
# source "$(dirname "$0")/00_logging.sh"

if ! command -v starship >/dev/null 2>&1; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

echo "Starship installed. Ensure your .zshrc has: eval \"\$(starship init zsh)\""
