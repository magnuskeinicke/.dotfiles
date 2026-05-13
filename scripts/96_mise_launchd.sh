#!/usr/bin/env bash
# Installs ~/Library/LaunchAgents/io.melatech.mise-path.plist on macOS so that
# GUI-launched apps (Claude Desktop, Conductor, Raycast, …) inherit a PATH
# containing the mise shims directory. No-op on non-macOS systems.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./_os.sh
source "$REPO_DIR/scripts/_os.sh"

if [ "$IS_MACOS" != "1" ]; then
  echo "Not macOS (OS_FAMILY=$OS_FAMILY) — skipping mise PATH LaunchAgent."
  exit 0
fi

LABEL="io.melatech.mise-path"
SRC="$REPO_DIR/mac/launchd/${LABEL}.plist"
DST_DIR="$HOME/Library/LaunchAgents"
DST="$DST_DIR/${LABEL}.plist"

if [ ! -f "$SRC" ]; then
  echo "ERROR: ${SRC} not found." >&2
  exit 1
fi

mkdir -p "$DST_DIR"
ln -sfn "$SRC" "$DST"
echo "Linked: $DST -> $SRC"

DOMAIN="gui/$(id -u)"

# Reload the agent (bootout is fine if it isn't currently loaded).
launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$DST"
launchctl kickstart -k "${DOMAIN}/${LABEL}"

echo "✅ ${LABEL} loaded. New GUI apps will see the mise shims in PATH."
echo "   (Restart already-running GUI apps for them to pick up the change.)"
