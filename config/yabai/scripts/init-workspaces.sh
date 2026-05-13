#!/usr/bin/env bash
# Ensure each connected display has at least MIN_PER_DISPLAY spaces.
# Run from yabairc at startup so the predefined workspaces always exist
# (matching the baseline the cleanup script preserves).
#
# Safe to re-run: it only creates missing spaces, never destroys.

MIN_PER_DISPLAY=5

# Remember the focused display so we can restore it at the end —
# creating a space requires focusing its target display.
original=$(yabai -m query --displays --display 2>/dev/null | jq -r '.index // empty')

for did in $(yabai -m query --displays 2>/dev/null | jq -r '.[].index'); do
  count=$(yabai -m query --spaces --display "$did" | jq 'length')
  while [ "$count" -lt "$MIN_PER_DISPLAY" ]; do
    yabai -m display --focus "$did" 2>/dev/null
    yabai -m space --create
    count=$(yabai -m query --spaces --display "$did" | jq 'length')
  done
done

# Best-effort restore — yabai returns non-zero when "focusing" the
# already-focused display, which is fine.
[ -n "$original" ] && yabai -m display --focus "$original" 2>/dev/null || true
