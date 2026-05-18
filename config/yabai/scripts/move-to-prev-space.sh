#!/usr/bin/env bash
# Move the focused window to the previous space on the SAME display.
# No-op if already on the first space of this display.

set -e

snapshot=$(yabai -m query --spaces)

read -r source_idx disp <<<"$(jq -r '.[] | select(."has-focus") | "\(.index) \(.display)"' <<<"$snapshot")"
[ -z "$source_idx" ] && exit 0

target=$(jq -r --argjson cur "$source_idx" --argjson d "$disp" '
    [.[] | select(.display == $d and .index < $cur)]
    | sort_by(.index) | reverse | .[0].index // empty' <<<"$snapshot")

[ -z "$target" ] && exit 0

yabai -m window --space "$target" --focus

"$(dirname "$0")/cleanup-space.sh" "$source_idx"
