#!/usr/bin/env bash
# One-shot full opacity sweep. Run once from yabairc at startup so all
# existing windows pick up correct active/normal opacity values. After
# this, refresh-opacity.sh handles updates incrementally on focus events.

ACTIVE=0.95
NORMAL=0.8
STATE="${TMPDIR:-/tmp}/yabai-last-focused.$(id -u)"

focused=$(yabai -m query --windows --window 2>/dev/null | jq -r '.id // empty')

yabai -m query --windows 2>/dev/null \
  | jq -r --argjson f "${focused:-0}" --argjson a "$ACTIVE" --argjson n "$NORMAL" '
      .[]
      | select(."is-visible")
      | "\(.id) \(if .id == $f then $a else $n end)"
  ' \
  | while read -r id op; do
      yabai -m window "$id" --opacity "$op" 2>/dev/null || true
    done

[ -n "$focused" ] && printf '%s' "$focused" > "$STATE"
