#!/usr/bin/env sh

# Load Theme colors if available
THEME_FILE="$HOME/.config/themes/current/shellcolors.sh"
if [ -r "$THEME_FILE" ]; then
  source "$THEME_FILE"
else
  ACTIVE=0xfffe8019
fi

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.drawing=on \
                           background.color="$ACTIVE" \
                           icon.color=0xff111111
else
  sketchybar --set "$NAME" background.drawing=on \
                           background.color=0x00000000 \
                           icon.color=0xffffffff
fi
