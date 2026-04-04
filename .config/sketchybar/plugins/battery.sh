#!/usr/bin/env sh

PERCENT=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ "$PERCENT" = "" ]; then
  exit 0
fi

# Default colors (adjust if you have specific theme variables)
COLOR=0xffffffff
case ${PERCENT} in
  9[0-9]|100) 
    ICON="󰁹"
    COLOR=0xffa6da95 # Green
    ;;
  [7-8][0-9]) 
    ICON="󰂄"
    COLOR=0xffa6da95 # Green
    ;;
  [4-6][0-9]) 
    ICON="󰁾"
    COLOR=0xffeed49f # Yellow
    ;;
  [1-3][0-9]) 
    ICON="󰁼"
    COLOR=0xfff5a97f # Orange
    ;;
  *) 
    ICON="󰂃"
    COLOR=0xffed8796 # Red
esac

if [ "$CHARGING" != "" ]; then
  ICON="󰂄"
  COLOR=0xff8aadf4 # Blue/Charging
fi

sketchybar --set "$NAME" icon="$ICON" \
                         label="${PERCENT}%" \
                         icon.color="$COLOR"
