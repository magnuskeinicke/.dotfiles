#!/usr/bin/env bash
# Move the focused window to the next space, COSMIC-style: if there is
# no next space, create one first. Requires yabai's scripting addition
# (which yabairc already loads).

set -e

current_idx=$(yabai -m query --spaces --space | jq -r '.index')
last_idx=$(yabai -m query --spaces | jq -r '[.[].index] | max')

if [ "$current_idx" -ge "$last_idx" ]; then
  yabai -m space --create
  # yabai appends the new space at the end; pick whatever the new max is
  # rather than assuming last_idx+1, in case another display shares numbering.
  target=$(yabai -m query --spaces | jq -r '[.[].index] | max')
  yabai -m window --space "$target" --focus
else
  yabai -m window --space next --focus
fi

# The space we just left might now be empty — clean it up if it's beyond
# the predefined baseline. window_destroyed signals don't fire on moves.
"$(dirname "$0")/cleanup-empty-spaces.sh"
