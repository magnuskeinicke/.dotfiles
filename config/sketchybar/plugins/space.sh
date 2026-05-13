#!/usr/bin/env bash
# Toggle highlight on a workspace pill when yabai changes the active space.
# $SELECTED is set by sketchybar based on associated_space + space_change.
if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" \
    background.color=0xffcba6f7 \
    icon.color=0xff1e1e2e
else
  sketchybar --set "$NAME" \
    background.color=0xff313244 \
    icon.color=0xffcdd6f4
fi
