#!/usr/bin/env bash
set -euo pipefail

# install mise if missing
if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi

export PATH="$HOME/.local/bin:$PATH"

# sanity check that config is linked
if [ ! -f "$HOME/.config/mise/config.toml" ]; then
  echo "ERROR: ~/.config/mise/config.toml not found."
  echo "Run: make link"
  exit 1
fi

# install everything declared in config.toml
mise install

# optional: ensure tools are up to date (your call)
# mise upgrade

