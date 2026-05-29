#!/usr/bin/env bash
# Ensure each connected display has at least MIN_PER_DISPLAY spaces.
# Run from yabairc at startup so the predefined workspaces always exist
# (matching the baseline the cleanup script preserves).
#
# Safe to re-run: it only creates missing spaces, never destroys.

MIN_PER_DISPLAY=3
# Hard cap per iteration. During a boot-time display storm `display --focus`
# can silently fail (display not yet stable), causing `space --create` to
# land on the wrong display — the per-display count never reaches the
# baseline and an unbounded loop spawns dozens of orphan spaces. Cap +
# focus-verification stops that cold.
MAX_CREATES=5

# Remember the focused display so we can restore it at the end —
# creating a space requires focusing its target display.
original=$(yabai -m query --displays --display 2>/dev/null | jq -r '.index // empty')

for did in $(yabai -m query --displays 2>/dev/null | jq -r '.[].index'); do
  count=$(yabai -m query --spaces --display "$did" | jq 'length')
  created=0
  while [ "$count" -lt "$MIN_PER_DISPLAY" ] && [ "$created" -lt "$MAX_CREATES" ]; do
    # Verify the focus actually landed before creating — otherwise the new
    # space lands on whatever display currently has focus.
    yabai -m display --focus "$did" 2>/dev/null || true
    focused=$(yabai -m query --displays --display 2>/dev/null | jq -r '.index // empty')
    if [ "$focused" != "$did" ]; then
      break
    fi
    yabai -m space --create || break
    created=$((created + 1))
    count=$(yabai -m query --spaces --display "$did" | jq 'length')
  done
done

# Best-effort restore — yabai returns non-zero when "focusing" the
# already-focused display, which is fine.
[ -n "$original" ] && yabai -m display --focus "$original" 2>/dev/null || true
