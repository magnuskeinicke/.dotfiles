#!/usr/bin/env bash
set -euo pipefail

# Installs JetBrainsMono Nerd Font for the current user. Idempotent.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./_os.sh
source "$REPO_DIR/scripts/_os.sh"

FONT_NAME="JetBrainsMono Nerd Font"

if [ "$OS_FAMILY" = "macos" ]; then
  # macOS: prefer the brew cask (already in Brewfile). Fall back to manual.
  if command -v brew >/dev/null 2>&1 && brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    echo "✅ '$FONT_NAME' already installed via Homebrew. Skipping."
    exit 0
  fi
  if command -v brew >/dev/null 2>&1; then
    echo "==> Installing '$FONT_NAME' via Homebrew cask..."
    brew install --cask font-jetbrains-mono-nerd-font
    exit 0
  fi
  FONT_DIR="$HOME/Library/Fonts"
else
  FONT_DIR="$HOME/.local/share/fonts"
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$FONT_DIR"

# quick check: if font is already present, skip
if [ "$IS_LINUX" = "1" ] && command -v fc-list >/dev/null 2>&1; then
  if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    echo "✅ '$FONT_NAME' already present. Skipping."
    exit 0
  fi
elif ls "$FONT_DIR" 2>/dev/null | grep -qi "JetBrainsMono"; then
  echo "✅ '$FONT_NAME' already present in $FONT_DIR. Skipping."
  exit 0
fi

echo "==> Fetching latest JetBrainsMono Nerd Font release URL..."
ZIP_URL="$(
  curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
  | grep -Eo '"browser_download_url": *"[^"]*JetBrainsMono[^"]*\.zip"' \
  | head -n 1 \
  | sed -E 's/.*"(https[^"]+)"/\1/'
)"

if [[ -z "${ZIP_URL:-}" ]]; then
  echo "ERROR: Could not find JetBrainsMono zip in latest nerd-fonts release."
  exit 1
fi

echo "==> Downloading: $ZIP_URL"
curl -fsSL "$ZIP_URL" -o "$TMP_DIR/JetBrainsMono.zip"

echo "==> Unzipping to $FONT_DIR"
unzip -qo "$TMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR"

# Remove docs / Windows-only files (harmless if absent)
find "$FONT_DIR" -maxdepth 1 -type f \( -iname "*Windows Compatible*" -o -iname "*.txt" -o -iname "*.md" \) -delete || true

if [ "$IS_LINUX" = "1" ] && command -v fc-cache >/dev/null 2>&1; then
  echo "==> Rebuilding font cache"
  fc-cache -f "$FONT_DIR" >/dev/null
fi

echo "✅ Installed '$FONT_NAME' to $FONT_DIR"
if [ "$IS_LINUX" = "1" ]; then
  echo "NOTE: You may need to select it in GNOME Tweaks / Settings for Terminal(s)."
else
  echo "NOTE: Terminal apps usually pick it up immediately; restart if not."
fi
