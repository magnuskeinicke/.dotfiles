#!/usr/bin/env bash
# Diff-only opacity refresh, fired by yabai's window_focused signal.
#
# Replaces a full-sweep that ran N+2 yabai socket calls per focus event
# (one query for "who's focused", one for "all windows", then one
# `--opacity` set per visible window). The old approach made every
# focus change scale with window count and ran across five different
# signals — application_activated, display_changed, space_changed,
# window_created, window_focused — which all coalesce into the same
# window_focused emission anyway. At 5–10 ms per yabai socket
# round-trip the lag was visible.
#
# This script keeps the previous focus in /tmp and only dims that one
# window + brightens the new one. Cost is constant: 2 yabai window
# commands + 1 query, regardless of window count.
#
# Initial state for all visible windows is set once by init-opacity.sh
# from yabairc.

set -e

ACTIVE=0.95
NORMAL=0.8
STATE="${TMPDIR:-/tmp}/yabai-last-focused.$(id -u)"

cur=$(yabai -m query --windows --window 2>/dev/null | jq -r '.id // empty')
[ -z "$cur" ] && exit 0

prev=$(cat "$STATE" 2>/dev/null || true)
[ "$prev" = "$cur" ] && exit 0

yabai -m window "$cur" --opacity "$ACTIVE" 2>/dev/null || true
[ -n "$prev" ] && yabai -m window "$prev" --opacity "$NORMAL" 2>/dev/null || true

printf '%s' "$cur" > "$STATE"
