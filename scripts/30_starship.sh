#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./_os.sh
source "$REPO_DIR/scripts/_os.sh"

if command -v starship >/dev/null 2>&1; then
  echo "Starship already installed."
elif [ "$OS_FAMILY" = "macos" ]; then
  brew install starship
else
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

echo "Starship installed. Ensure your .zshrc has: eval \"\$(starship init zsh)\""
