#!/usr/bin/env bash
# Move the focused window horizontally with COSMIC fall-through:
#   1. Try to swap with the neighbor window in the given direction.
#   2. If there is no neighbor (we're at the workspace edge), fall through:
#        east → move window to next space, creating one if needed
#        west → move window to previous space (no-op if already first)
#
# Usage:  swap-or-move.sh east | west

set -e

DIR="$1"

if yabai -m window --swap "$DIR" 2>/dev/null; then
  exit 0
fi

case "$DIR" in
  east)
    exec "$(dirname "$0")/move-to-next-space.sh"
    ;;
  west)
    yabai -m window --space prev --focus 2>/dev/null || true
    "$(dirname "$0")/cleanup-empty-spaces.sh"
    ;;
  *)
    echo "swap-or-move.sh: unknown direction '$DIR' (expected east|west)" >&2
    exit 1
    ;;
esac
