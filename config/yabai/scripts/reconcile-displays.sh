#!/usr/bin/env bash
# Re-sync yabai spaces and SketchyBar after a display topology change
# (plug, unplug, lid open/close with external displays attached).
#
# Triggered by yabai signals: display_added, display_removed.
# Also safe to invoke manually after a hotplug glitch.
#
# Sequence:
#   1. Ensure each connected display has the MIN_PER_DISPLAY baseline.
#   2. Destroy empty non-baseline spaces (those may have been left over
#      from a now-disconnected display that yabai reassigned).
#   3. Rebuild SketchyBar's per-display bar instances. `sketchybar --reload`
#      re-runs sketchybarrc, which recreates pills via spaces_refresh.sh.
#      Without this, pills can render on the wrong display when a bar
#      instance is missing for a newly-attached screen.
#
# Serialize concurrent runs — display_added + display_removed can fire
# in quick succession during a lid close/open cycle.

LOCK=/tmp/reconcile-displays.lock
for _ in $(seq 1 200); do
  mkdir "$LOCK" 2>/dev/null && break
  sleep 0.05
done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

# Brief settle wait — macOS reports the display change before the
# CGDisplay topology is fully stable, and creating spaces too early
# can land them on the wrong display.
sleep 0.5

"$HOME/.config/yabai/scripts/init-workspaces.sh"
"$HOME/.config/yabai/scripts/cleanup-empty-spaces.sh"

# Reload sketchybar so per-display bar instances regenerate. Falls back
# to a manual trigger if reload isn't available (older builds).
if ! sketchybar --reload 2>/dev/null; then
  "$HOME/.config/sketchybar/plugins/spaces_refresh.sh" >/dev/null 2>&1 &
fi
