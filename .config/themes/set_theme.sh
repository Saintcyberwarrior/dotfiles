#!/bin/bash

THEME_DIR="$HOME/.config/themes"
WALLPAPER_DIR="$HOME/.config/wallpapers"

setwall() {
  local WALLPAPER="$1"

  if [ -z "$WALLPAPER" ]; then
    echo "Usage: setwall /path/to/wallpaper.jpg" >&2
    return 1
  fi

  if [ ! -f "$WALLPAPER" ]; then
    echo "Error: File not found: $WALLPAPER" >&2
    return 1
  fi

  # Resolve to absolute path
  local ABS_PATH="$(cd "$(dirname "$WALLPAPER")"; pwd)/$(basename "$WALLPAPER")"

  local COUNT
  COUNT=$(osascript <<EOF 2>&1
tell application "System Events"
    set numSpaces to count of desktops
    repeat with d in desktops
        set picture of d to POSIX file "$ABS_PATH"
    end repeat
    return numSpaces
end tell
EOF
)

  echo "✅ Wallpaper applied to $COUNT space(s) across all displays."
}

case "$1" in
  "Catppuccin")
    echo "Switching to Catppuccin!"
    ln -sf $THEME_DIR/catppuccin/* $THEME_DIR/current
    setwall $WALLPAPER_DIR/catppuccin1.jpeg
    ;;
  "Gruvbox")
    echo "Switching to Gruvbox!"
    ln -sf $THEME_DIR/gruvbox/* $THEME_DIR/current
    setwall $WALLPAPER_DIR/gruvbox1.jpeg
    ;;
  *)
    echo "Invalid theme"
    exit
    ;;
esac

if command -v sketchybar >/dev/null; then
  sketchybar --reload
fi

# Borders might be installed via homebrew
if brew services list | grep -q borders; then
  brew services restart borders
fi

touch $HOME/.wezterm.lua
