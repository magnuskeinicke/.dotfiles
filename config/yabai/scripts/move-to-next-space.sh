#!/usr/bin/env bash
# Move the focused window to the next space on the SAME display.
# If there is no next space on this display, create one (on this display)
# and move the window there. Window-focus follows.
#
# Requires yabai's scripting addition (loaded by yabairc).

set -e

snapshot=$(yabai -m query --spaces)

read -r source_idx disp <<<"$(jq -r '.[] | select(."has-focus") | "\(.index) \(.display)"' <<<"$snapshot")"
[ -z "$source_idx" ] && exit 0

# Next space index on the same display, if any.
target=$(jq -r --argjson cur "$source_idx" --argjson d "$disp" '
    [.[] | select(.display == $d and .index > $cur)]
    | sort_by(.index) | .[0].index // empty' <<<"$snapshot")

if [ -z "$target" ]; then
  # At the last space of this display — create a new one here.
  # `space --create` creates on the focused display.
  yabai -m space --create
  # New space lands as the highest index on this display.
  target=$(yabai -m query --spaces | jq -r --argjson d "$disp" '
      [.[] | select(.display == $d) | .index] | max')
fi

yabai -m window --space "$target" --focus

# Targeted cleanup of just the source space.
"$(dirname "$0")/cleanup-space.sh" "$source_idx"

# Refresh the bar deterministically. yabai's space_created signal also
# fires this script, but that handler races with this script's flow —
# direct call here guarantees the pill exists before we return.
"${HOME}/.config/sketchybar/plugins/spaces_refresh.sh" >/dev/null 2>&1 &
