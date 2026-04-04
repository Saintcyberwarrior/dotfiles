#!/usr/bin/env sh

# The $INFO variable contains the volume percentage
VOLUME="$INFO"

if [ "$VOLUME" = "" ]; then
  VOLUME=$(osascript -e "output volume of (get volume settings)")
fi

case "$VOLUME" in
  [6-9][0-9]|100) 
    ICON="󰕾" 
    COLOR=0xff8aadf4 # Blue
    ;;
  [3-5][0-9]) 
    ICON="󰖀" 
    COLOR=0xffffffff 
    ;;
  [1-9]|[1-2][0-9]) 
    ICON="󰕿" 
    COLOR=0xffffffff 
    ;;
  *) 
    ICON="󰝟" 
    COLOR=0xffed8796 # Red/Muted
esac

sketchybar --set "$NAME" icon="" \
                         icon="$ICON" \
                         label="$VOLUME%" \
                         icon.color="$COLOR"
