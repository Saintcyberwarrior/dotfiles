#!/usr/bin/env bash
set -euo pipefail

LOG="/tmp/sketchybar_media_debug.log"
STATE_FILE="/tmp/sketchybar_mediaremote.json"
LOCK_DIR="/tmp/sketchybar_media_widget.lock"

# Signature so you can verify which version is running
echo "[SIGNATURE] media.sh (rmpc song + reliable media-control + debounce) $(date)" >>"$LOG"

JQ="$(command -v jq || true)"
RMPC="$(command -v rmpc || true)"
MPC="$(command -v mpc || true)"
MC="$(command -v media-control || true)"
[ -x /opt/homebrew/bin/media-control ] && MC="/opt/homebrew/bin/media-control"

MAX_TITLE=28
MAX_ARTIST=18

log() { echo "[$(date '+%H:%M:%S')] $*" >>"$LOG"; }

truncate_text() {
  local text="${1:-}"
  local max="${2:-30}"
  text="${text//$'\n'/ }"
  text="$(echo "$text" | awk '{$1=$1};1')"
  if [ "${#text}" -le "$max" ]; then
    echo "$text"
  else
    echo "${text:0:max}" | sed -E 's/\s+[[:alnum:]]*$//' | awk '{$1=$1};1' | sed 's/$/.../'
  fi
}

# Debounce sketchybar updates (reduces flicker/glitchiness)
last_icon=""
last_label=""
set_if_changed() {
  local icon="$1"
  local label="$2"
  if [ "$icon" != "$last_icon" ] || [ "$label" != "$last_label" ]; then
    sketchybar --set media icon="$icon" label="$label"
    last_icon="$icon"
    last_label="$label"
  fi
}

# Prevent duplicates
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

log "START: rmpc=$RMPC mpc=$MPC media-control=$MC jq=$JQ"

# Always visible default
set_if_changed "" ""

# Start media-control listener (browser/YouTube/etc) if available
if [ -n "${MC:-}" ] && [ -n "${JQ:-}" ]; then
  log "Starting media-control stream listener..."
  ("$MC" stream 2>>"$LOG" || true) | while IFS= read -r line; do
    # Reliable: cache any event that has a payload.title (diff gating drops updates)
    title="$("$JQ" -r '.payload.title // empty' <<<"$line" 2>/dev/null || true)"
    if [ -n "$title" ]; then
      echo "$line" >"$STATE_FILE" 2>/dev/null || true
    fi
  done &
else
  log "media-control or jq not found; browser playback won't show."
fi

get_mpd() {
  # Output: state|title|artist where state is Play/Pause/Stop/none

  # rmpc
  if [ -n "${RMPC:-}" ] && [ -n "${JQ:-}" ]; then
    local st_js state song_js title artist

    st_js="$("$RMPC" status 2>/dev/null || true)"
    state="$("$JQ" -r '.state // "none"' <<<"$st_js" 2>/dev/null || echo none)"

    # song metadata
    song_js="$("$RMPC" song 2>/dev/null || true)"
    title="$("$JQ" -r '.metadata.title // empty' <<<"$song_js" 2>/dev/null || true)"
    artist="$("$JQ" -r '.metadata.artist // empty' <<<"$song_js" 2>/dev/null || true)"

    # fallback to filename
    if [ -z "$title" ]; then
      title="$("$JQ" -r '.file // empty' <<<"$song_js" 2>/dev/null || true)"
    fi

    echo "$state|$title|$artist"
    return 0
  fi

  # Fallback: mpc if installed
  if [ -n "${MPC:-}" ]; then
    local out state="Stop"
    out="$("$MPC" status 2>/dev/null || true)"
    if echo "$out" | grep -q "\[playing\]"; then state="Play"; fi
    if echo "$out" | grep -q "\[paused\]"; then state="Pause"; fi

    local title artist
    title="$("$MPC" current -f '%title%' 2>/dev/null || true)"
    artist="$("$MPC" current -f '%artist%' 2>/dev/null || true)"
    [ -z "$title" ] && title="$("$MPC" current 2>/dev/null || true)"
    echo "$state|$title|$artist"
    return 0
  fi

  echo "none||"
}

get_mediaremote() {
  # Output: title|artist
  if [ -f "$STATE_FILE" ] && [ -n "${JQ:-}" ]; then
    local raw title artist
    raw="$(cat "$STATE_FILE" 2>/dev/null || echo '')"
    title="$("$JQ" -r '.payload.title // empty' <<<"$raw" 2>/dev/null || true)"
    artist="$("$JQ" -r '.payload.artist // empty' <<<"$raw" 2>/dev/null || true)"
    echo "$title|$artist"
  else
    echo "|"
  fi
}

while true; do
  mpd_line="$(get_mpd)"
  mpd_state="${mpd_line%%|*}"
  rest="${mpd_line#*|}"
  mpd_title="${rest%%|*}"
  mpd_artist="${rest#*|}"

  mr_line="$(get_mediaremote)"
  mr_title="${mr_line%%|*}"
  mr_artist="${mr_line#*|}"

  # Priority:
  # 1) MPD when playing
  # 2) Browser/media-control when available
  # 3) MPD paused (optional: show track)
  # 4) Placeholder

  if [ "$mpd_state" = "Play" ] && [ -n "$mpd_title" ]; then
    t="$(truncate_text "$mpd_title" "$MAX_TITLE")"
    a="$(truncate_text "$mpd_artist" "$MAX_ARTIST")"
    label="$t"
    [ -n "$a" ] && label="$t – $a"
    set_if_changed "􀊆" "$label"

  elif [ -n "$mr_title" ]; then
    t="$(truncate_text "$mr_title" "$MAX_TITLE")"
    a="$(truncate_text "$mr_artist" "$MAX_ARTIST")"
    label="$t"
    [ -n "$a" ] && label="$t – $a"
    set_if_changed "􀑪" "$label"

  elif [ "$mpd_state" = "Pause" ] && [ -n "$mpd_title" ]; then
    t="$(truncate_text "$mpd_title" "$MAX_TITLE")"
    a="$(truncate_text "$mpd_artist" "$MAX_ARTIST")"
    label="$t"
    [ -n "$a" ] && label="$t – $a"
    set_if_changed "􀊄" "$label"

  else
    set_if_changed "" ""
  fi

  sleep 1
done
