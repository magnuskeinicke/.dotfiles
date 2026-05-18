#!/usr/bin/env bash
# Cycle spaces by global index across all displays, wrapping at the ends.
# Used by rcmd+tab (next) and rcmd+shift+tab (prev).
#
# Usage:  space-cycle-index.sh next | prev

set -e

DIR="$1"

case "$DIR" in
  next|prev) ;;
  *) echo "space-cycle-index.sh: bad direction '$DIR'" >&2; exit 1 ;;
esac

# Single query returns every space plus a has-focus flag — one socket
# round-trip instead of two.
read -r current rest < <(yabai -m query --spaces | jq -r '
    sort_by(.index)
    | [(map(select(."has-focus")) | .[0].index), [.[].index]]
    | "\(.[0]) \(.[1] | join(" "))"
  ')
read -ra spaces <<<"$rest"
count=${#spaces[@]}
[ "$count" -lt 2 ] && exit 0

pos=-1
for i in "${!spaces[@]}"; do
  [ "${spaces[$i]}" = "$current" ] && { pos=$i; break; }
done
[ "$pos" -lt 0 ] && exit 0

case "$DIR" in
  next) target_pos=$(( (pos + 1) % count )) ;;
  prev) target_pos=$(( (pos - 1 + count) % count )) ;;
esac

yabai -m space --focus "${spaces[$target_pos]}"
