#!/usr/bin/env bash
# Reconcile space.* items in SketchyBar against yabai's current spaces.
# Adds pills for new spaces, removes pills for destroyed ones. Run once
# from sketchybarrc at startup, and again whenever yabai signals that
# a space was created or destroyed.

PLUGIN_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}/plugins"

# Catppuccin Mocha — must match sketchybarrc.
SURFACE=0xff313244

# Wait briefly for yabai to be ready. On a cold boot sketchybar can start
# before yabai's socket is listening; without this retry we'd add zero
# pills and the bar would have no workspace indicators until manual reload.
SPACES_JSON='[]'
for _ in $(seq 1 20); do
  SPACES_JSON=$(yabai -m query --spaces 2>/dev/null || echo '[]')
  [ "$SPACES_JSON" != '[]' ] && [ -n "$SPACES_JSON" ] && break
  sleep 0.5
done
WANT_IDX=$(echo "$SPACES_JSON" | jq -r '.[].index')

EXISTING=$(sketchybar --query bar 2>/dev/null \
            | jq -r '.items[]' \
            | grep '^space\.' || true)

# Remove pills for spaces yabai no longer has.
for item in $EXISTING; do
  idx="${item#space.}"
  if ! echo "$WANT_IDX" | grep -qx "$idx"; then
    sketchybar --remove "$item"
  fi
done

# Add pills for spaces yabai has but sketchybar doesn't.
for idx in $WANT_IDX; do
  if echo "$EXISTING" | grep -qx "space.$idx"; then
    continue
  fi
  did=$(echo "$SPACES_JSON" | jq -r ".[] | select(.index==$idx) | .display")
  sketchybar --add space "space.$idx" left \
             --set "space.$idx" \
                associated_space=$idx \
                display=$did \
                icon="$idx" \
                icon.padding_left=10 \
                icon.padding_right=10 \
                label.drawing=off \
                background.color=$SURFACE \
                background.drawing=on \
                click_script="yabai -m space --focus $idx" \
                script="$PLUGIN_DIR/space.sh" \
             --subscribe "space.$idx" space_change display_change
done

sketchybar --update
