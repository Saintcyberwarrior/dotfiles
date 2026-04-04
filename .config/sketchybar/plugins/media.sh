#!/usr/bin/env bash

# Signature for version tracking
# VERSION: 2.1

# Check if we are being called to update or to start the background listener
if [ "${1:-}" = "listen" ]; then
  MC="/opt/homebrew/bin/media-control"
  STATE_FILE="/tmp/sketchybar_mediaremote.json"
  if [ -x "$MC" ]; then
    "$MC" stream | while read -r line; do
       echo "$line" > "$STATE_FILE"
       sketchybar --trigger media_change
    done
  fi
  exit 0
fi

JQ="/usr/bin/jq"
RMPC="/run/current-system/sw/bin/rmpc"
STATE_FILE="/tmp/sketchybar_mediaremote.json"

MAX_TITLE=25

truncate_text() {
  local text="$1"
  if [ ${#text} -gt $MAX_TITLE ]; then
    echo "${text:0:$MAX_TITLE}..."
  else
    echo "$text"
  fi
}

# 1. Check RMPC (MPD)
if [ -x "$RMPC" ]; then
  STATUS="$("$RMPC" status 2>/dev/null)"
  if [ -n "$STATUS" ]; then
    STATE=$(echo "$STATUS" | "$JQ" -r '.state')
    if [ "$STATE" = "Play" ]; then
      SONG="$("$RMPC" song 2>/dev/null)"
      TITLE=$(echo "$SONG" | "$JQ" -r '.metadata.title // .file | split("/") | last')
      LABEL=$(truncate_text "$TITLE")
      sketchybar --set media icon="▶" label="$LABEL" drawing=on
      exit 0
    elif [ "$STATE" = "Pause" ]; then
      SONG="$("$RMPC" song 2>/dev/null)"
      TITLE=$(echo "$SONG" | "$JQ" -r '.metadata.title // .file | split("/") | last')
      LABEL=$(truncate_text "$TITLE")
      sketchybar --set media icon="󰏤" label="$LABEL" drawing=on
      exit 0
    fi
  fi
fi

# 2. Check MediaRemote (Browser/System)
if [ -f "$STATE_FILE" ]; then
  RAW=$(cat "$STATE_FILE")
  TITLE=$(echo "$RAW" | "$JQ" -r '.payload.title // ""')
  
  if [ -n "$TITLE" ]; then
    LABEL=$(truncate_text "$TITLE")
    sketchybar --set media icon="▶" label="$LABEL" drawing=on
    exit 0
  fi
fi

# Fallback: Hide
sketchybar --set media drawing=off
