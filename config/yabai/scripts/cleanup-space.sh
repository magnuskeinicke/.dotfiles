#!/usr/bin/env bash
# Destroy a single space if it is now empty, not focused, and its display
# already has more than MIN_PER_DISPLAY spaces. Intended for the
# window-move helpers, which know exactly which space they just left —
# so they call this with that space index instead of a blanket sweep.
#
# Usage:  cleanup-space.sh <space-index>

MIN_PER_DISPLAY=3

target="${1:-}"
[ -z "$target" ] && exit 0

yabai -m query --spaces 2>/dev/null \
  | jq -e --argjson t "$target" --argjson min "$MIN_PER_DISPLAY" '
      . as $all
      | ($all[] | select(.index == $t)) as $sp
      | $sp
      | select(."has-focus" | not)
      | select((.windows // []) | length == 0)
      | select(([$all[] | select(.display == $sp.display)] | length) > $min)
  ' >/dev/null || exit 0

yabai -m space --destroy "$target" 2>/dev/null || true
