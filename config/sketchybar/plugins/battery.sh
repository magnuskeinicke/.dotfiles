#!/usr/bin/env bash
# Battery indicator. MDI glyphs written as UTF-8 hex via printf — works in
# macOS's bash 3.2 (which lacks $'\U...' support).

BATT=$(pmset -g batt)
PERCENT=$(echo "$BATT" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
STATE=$(echo "$BATT" | awk -F';' '/InternalBattery/ {print $2}' | xargs)

if [ -z "$PERCENT" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

if   [[ "$STATE" == *charging* || "$STATE" == *charged* ]]; then
  ICON=$(printf '\xF3\xB0\x82\x84')    # battery-charging   U+F0084
elif (( PERCENT >= 90 )); then
  ICON=$(printf '\xF3\xB0\x81\xB9')    # battery (full)     U+F0079
elif (( PERCENT >= 70 )); then
  ICON=$(printf '\xF3\xB0\x82\x82')    # battery-80         U+F0082
elif (( PERCENT >= 50 )); then
  ICON=$(printf '\xF3\xB0\x82\x80')    # battery-60         U+F0080
elif (( PERCENT >= 30 )); then
  ICON=$(printf '\xF3\xB0\x81\xBE')    # battery-40         U+F007E
elif (( PERCENT >= 10 )); then
  ICON=$(printf '\xF3\xB0\x81\xBC')    # battery-20         U+F007C
else
  ICON=$(printf '\xF3\xB0\x82\x83')    # battery-alert      U+F0083
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENT}%"
