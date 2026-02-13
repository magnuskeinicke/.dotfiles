#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"

command -v nvim >/dev/null 2>&1 || { echo "nvim not found"; exit 0; }

nvim --headless +"Lazy! sync" +qa || true
nvim --headless +"TSUpdate" +qa || true
