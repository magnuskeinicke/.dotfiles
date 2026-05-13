#!/usr/bin/env bash
# Install/refresh the NOPASSWD sudoers rule for `yabai --load-sa`.
# The rule is hash-pinned to the current yabai binary, so it must be
# regenerated whenever yabai is upgraded. This script is idempotent —
# if the existing rule already matches, it does nothing (no sudo prompt).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./_os.sh
source "$REPO_DIR/scripts/_os.sh"

if [ "$OS_FAMILY" != "macos" ]; then
  exit 0
fi

if ! command -v yabai >/dev/null 2>&1; then
  echo "==> yabai not installed; skipping scripting-addition sudoers setup."
  exit 0
fi

YABAI_PATH="$(command -v yabai)"
HASH="$(shasum -a 256 "$YABAI_PATH" | awk '{print $1}')"
USER_NAME="$(whoami)"
SUDOERS_PATH="/private/etc/sudoers.d/yabai"
LINE="$USER_NAME ALL=(root) NOPASSWD: sha256:$HASH $YABAI_PATH --load-sa"

# Idempotency: if the file exists and already contains the exact line, exit early.
if sudo -n test -r "$SUDOERS_PATH" 2>/dev/null \
   && sudo grep -qxF "$LINE" "$SUDOERS_PATH" 2>/dev/null; then
  echo "==> yabai scripting-addition sudoers rule already up-to-date."
  exit 0
fi

echo "==> Installing yabai scripting-addition sudoers rule at $SUDOERS_PATH"
echo "    (you may be prompted for your password)"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
echo "$LINE" > "$TMP"

# Validate syntax before installing.
sudo visudo -cf "$TMP" >/dev/null

sudo install -m 0440 -o root -g wheel "$TMP" "$SUDOERS_PATH"

echo "==> Done. Restart yabai to apply:  yabai --restart-service"
