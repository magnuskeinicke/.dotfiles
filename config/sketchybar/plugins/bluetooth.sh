#!/usr/bin/env bash
# Bluetooth indicator. UTF-8 hex via printf (bash 3.2 safe).

if ! command -v blueutil >/dev/null 2>&1; then
  sketchybar --set "$NAME" icon="?" label=""
  exit 0
fi

POWER=$(blueutil --power)
if [ "$POWER" -eq 0 ]; then
  ICON=$(printf '\xF3\xB0\x82\xB0')    # bluetooth-off  U+F00B0
  COLOR=0xff6c7086                      # dim (catppuccin overlay0)
else
  ICON=$(printf '\xF3\xB0\x82\xAF')    # bluetooth      U+F00AF
  COLOR=0xffcdd6f4                      # text
fi

sketchybar --set "$NAME" icon="$ICON" icon.color=$COLOR label=""
