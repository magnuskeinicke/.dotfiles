#!/usr/bin/env bash
# Focus the neighboring window in DIR. If there is no neighbor in the
# current space (we're at the screen edge), fall through to the adjacent
# display and focus the edge-most window facing the source direction.
#
# Usage:  focus-or-display.sh west | east | north | south

set -e

DIR="$1"

case "$DIR" in
  west|east|north|south) ;;
  *) echo "focus-or-display.sh: bad direction '$DIR'" >&2; exit 1 ;;
esac

# Step 1: try in-space focus.
if yabai -m window --focus "$DIR" 2>/dev/null; then
  exit 0
fi

# Step 2: no neighbor — try to focus the display in that direction.
if ! yabai -m display --focus "$DIR" 2>/dev/null; then
  exit 0
fi

# Step 3: focus the edge-most window on the newly focused space so that
# h/l/j/k feels continuous across the gap between displays.
case "$DIR" in
  east)  pick='min_by(.frame.x)' ;;
  west)  pick='max_by(.frame.x + .frame.w)' ;;
  south) pick='min_by(.frame.y)' ;;
  north) pick='max_by(.frame.y + .frame.h)' ;;
esac

win=$(yabai -m query --windows --space | jq -r "
  map(select(.\"is-visible\" and (.\"is-minimized\" | not)))
  | if length == 0 then empty else $pick | .id end
")

[ -n "$win" ] && yabai -m window --focus "$win"
