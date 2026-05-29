#!/usr/bin/env bash
# Destroy empty, non-focused spaces beyond a per-display baseline.
# Each display keeps the first MIN_PER_DISPLAY spaces as "predefined" —
# they stick around even when empty (you can pin specific apps to
# specific workspace numbers). Any space beyond that is dynamic and
# auto-cleans the moment its last window leaves.
#
# Called by yabai signals (window_destroyed, application_terminated)
# and by the window-move helpers (move-to-next-space.sh, swap-or-move.sh).

MIN_PER_DISPLAY=3

# Loop until a pass finds no destruction candidate. yabai reindexes
# spaces after each destroy, so we re-query every iteration. We always
# go after the highest-indexed candidate first — that way the indices
# of lower-numbered survivors are not affected by the destroy.
#
# A single destroy failure must NOT abort the whole sweep: during a
# boot-time display storm yabai can transiently refuse a single destroy
# while still able to destroy others. Track the victim instead and skip
# it on subsequent iterations to avoid an infinite loop on a stuck space.
SKIP=""
MAX_ITERS=200
iter=0
while [ "$iter" -lt "$MAX_ITERS" ]; do
  iter=$((iter + 1))
  victim=$(yabai -m query --spaces 2>/dev/null | jq -r \
      --argjson min "$MIN_PER_DISPLAY" \
      --arg skip "$SKIP" '
    ($skip | split(",") | map(select(length > 0) | tonumber)) as $skipset
    | [ group_by(.display)[]
        | sort_by(.index)
        | .[$min:][]?
        | select(."has-focus" | not)
        | select((.windows // []) | length == 0)
        | select(.index as $i | ($skipset | index($i)) | not)
        | .index
      ]
    | max // empty
  ')

  [ -z "$victim" ] && break
  if ! yabai -m space --destroy "$victim" 2>/dev/null; then
    SKIP="${SKIP:+$SKIP,}$victim"
  fi
done
