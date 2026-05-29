#!/usr/bin/env sh
# Move newly created standard windows to the currently focused space, so
# apps launched via Spotlight / Raycast / rcmd appear where focus is
# instead of macOS's main (menu-bar) display.
#
# Subsequent windows of already-running apps are unaffected by Spotlight
# (no window_created event fires — macOS just raises the app).

WIN="${YABAI_WINDOW_ID:-}"
[ -z "$WIN" ] && exit 0

INFO=$(yabai -m query --windows --window "$WIN" 2>/dev/null) || exit 0

# Only move top-level standard windows. Skip sheets, dialogs, popovers,
# and PiP-style floaters — moving those breaks the parent app's UX.
SUBROLE=$(printf '%s' "$INFO" | jq -r '.subrole // ""')
[ "$SUBROLE" != "AXStandardWindow" ] && exit 0

WIN_SPACE=$(printf '%s' "$INFO" | jq -r '.space')
FOCUS_SPACE=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index')

[ -z "$FOCUS_SPACE" ] && exit 0
[ "$WIN_SPACE" = "$FOCUS_SPACE" ] && exit 0

yabai -m window "$WIN" --space "$FOCUS_SPACE" 2>/dev/null
yabai -m window --focus "$WIN" 2>/dev/null
