#!/usr/bin/env bash
set -euo pipefail
# source "$(dirname "$0")/00_logging.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"


if [ ! -d "$ZSH" ]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

mkdir -p "$ZSH_CUSTOM/plugins"

clone_or_update () {
  local repo="$1"
  local name
  name="$(basename "$repo" .git)"
  local dest="$ZSH_CUSTOM/plugins/$name"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only
  else
    git clone --depth=1 "$repo" "$dest"
  fi
}

while read -r repo; do
  [[ -z "$repo" || "$repo" =~ ^# ]] && continue
  clone_or_update "$repo"
done < "$REPO_DIR/zsh/plugins.txt"

if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH="$(command -v zsh)"
  if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
    # macOS chsh requires the shell to be listed in /etc/shells.
    if [ -f /etc/shells ] && ! grep -qx "$ZSH_PATH" /etc/shells; then
      echo "Adding $ZSH_PATH to /etc/shells (requires sudo)"
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    echo "Setting default shell to zsh ($ZSH_PATH)..."
    chsh -s "$ZSH_PATH"
    echo "Default shell changed. It applies to NEW sessions."
  fi
fi

echo "Oh My Zsh installed + plugins updated."

