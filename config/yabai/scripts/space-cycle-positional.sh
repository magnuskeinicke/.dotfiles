#!/usr/bin/env bash
# Cycle spaces positionally: stay on the current display until its spaces
# run out, then jump to the adjacent display's first/last space.
#
# Direction conventions:
#   east → next space on this display; at the right edge → first space of
#          the east display.
#   west → previous space on this display; at the left edge → last space
#          of the west display.
#
# Usage:  space-cycle-positional.sh west | east

set -e

DIR="$1"

case "$DIR" in
  west|east) ;;
  *) echo "space-cycle-positional.sh: bad direction '$DIR'" >&2; exit 1 ;;
esac

# Single query for all spaces — the focused one carries .has-focus.
spaces=$(yabai -m query --spaces)

read -r current disp <<<"$(jq -r '.[] | select(."has-focus") | "\(.index) \(.display)"' <<<"$spaces")"

if [ "$DIR" = "east" ]; then
  target=$(jq -r --argjson cur "$current" --argjson d "$disp" '
      [.[] | select(.display == $d and .index > $cur)]
      | sort_by(.index) | .[0].index // empty' <<<"$spaces")
else
  target=$(jq -r --argjson cur "$current" --argjson d "$disp" '
      [.[] | select(.display == $d and .index < $cur)]
      | sort_by(.index) | reverse | .[0].index // empty' <<<"$spaces")
fi

if [ -n "$target" ]; then
  yabai -m space --focus "$target"
  exit 0
fi

# Edge of this display — hop to the neighboring display and pick its
# first (east-bound) or last (west-bound) space.
yabai -m display --focus "$DIR" 2>/dev/null || exit 0

# Reuse the same snapshot; displays didn't change, so spaces list is
# still valid. Grab the now-focused display index from yabai.
new_disp=$(yabai -m query --displays --display | jq -r '.index')

if [ "$DIR" = "east" ]; then
  target=$(jq -r --argjson d "$new_disp" '
      [.[] | select(.display == $d)] | sort_by(.index) | .[0].index' <<<"$spaces")
else
  target=$(jq -r --argjson d "$new_disp" '
      [.[] | select(.display == $d)] | sort_by(.index) | reverse | .[0].index' <<<"$spaces")
fi

[ -n "$target" ] && yabai -m space --focus "$target"
