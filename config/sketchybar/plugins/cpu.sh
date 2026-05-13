#!/usr/bin/env bash
CPU=$(top -l 1 -n 0 | awk '/^CPU usage/ {
  u = $3; sub(/%/, "", u)
  s = $5; sub(/%/, "", s)
  printf "%.0f", u + s
}')
ICON=$(printf '\xF3\xB0\xB8\x95')    # cpu-64-bit  U+F0E15
sketchybar --set "$NAME" icon="$ICON" label="${CPU}%"
