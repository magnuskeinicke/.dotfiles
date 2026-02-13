#!/usr/bin/env bash
set -euo pipefail

# Installs JetBrainsMono Nerd Font for the current user.
# Idempotent: skips if already installed.

FONT_NAME="JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$FONT_DIR"

# quick check: if font is already in fontconfig cache, skip
if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
  echo "✅ '$FONT_NAME' already present. Skipping."
  exit 0
fi

echo "==> Fetching latest JetBrainsMono Nerd Font release URL..."
ZIP_URL="$(
  curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
  | grep -Po '"browser_download_url": "\K[^"]*JetBrainsMono[^"]*\.zip' \
  | head -n 1
)"

if [[ -z "${ZIP_URL:-}" ]]; then
  echo "ERROR: Could not find JetBrainsMono zip in latest nerd-fonts release."
  exit 1
fi

echo "==> Downloading: $ZIP_URL"
curl -fsSL "$ZIP_URL" -o "$TMP_DIR/JetBrainsMono.zip"

echo "==> Unzipping to $FONT_DIR"
unzip -qo "$TMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR"

# Remove Windows/macOS stuff if present (harmless if absent)
find "$FONT_DIR" -maxdepth 1 -type f \( -iname "*Windows Compatible*" -o -iname "*.txt" -o -iname "*.md" \) -delete || true

echo "==> Rebuilding font cache"
fc-cache -f "$FONT_DIR" >/dev/null

echo "✅ Installed '$FONT_NAME' to $FONT_DIR"
echo "NOTE: You may need to select it in GNOME Tweaks / Settings for Terminal(s)."

