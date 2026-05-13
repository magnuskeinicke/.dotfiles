#!/usr/bin/env bash
ICON=$(printf '\xF3\xB0\x83\xAD')    # calendar  U+F00ED
sketchybar --set "$NAME" icon="$ICON" label="$(date '+%a %d %b  %H:%M')"
