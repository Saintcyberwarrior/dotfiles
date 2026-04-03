#!/usr/bin/env bash
set -euo pipefail

# Enhanced Lyrics Fetcher (macOS Compatible)
# Usage: ./fetch_lyrics.sh "/path/to/album" "/path/to/lyrics/output"
#        ./fetch_lyrics.sh --library "/path/to/music" "/path/to/lyrics/output"

LRCLIB_API="https://lrclib.net/api/get"
RATE_LIMIT_DELAY=0.5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}▶${NC} $*" >&2; }
log_success() { echo -e "${GREEN}✔${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*" >&2; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

# Check dependencies
check_dependencies() {
    local missing=()
    
    if ! command -v ffprobe &> /dev/null; then
        missing+=("ffprobe (install: brew install ffmpeg)")
    fi
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    if ! command -v jq &> /dev/null; then
        missing+=("jq (install: brew install jq)")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies:"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
}

# Get metadata from audio file
get_metadata() {
    local file="$1"
    local field="$2"
    
    local value
    value="$(ffprobe -v quiet -show_entries format_tags="$field" -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || true)"
    
    if [ -z "$value" ]; then
        value="$(ffprobe -v quiet -show_entries stream_tags="$field" -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || true)"
    fi
    
    echo "$value"
}

# Clean text for API search (macOS sed compatible)
clean_for_api() {
    local text="$1"
    echo "$text" | sed -E \
        -e 's/ *& */ and /g' \
        -e "s/'//g" \
        -e 's/[^a-zA-Z0-9 ]//g' \
        -e 's/  +/ /g' \
        -e 's/^ *//; s/ *$//' \
        -e 's/^[Tt]he //g' \
        -e 's/^[Aa] //g' \
        -e 's/^[Aa]n //g'
}

# Clean title for search (macOS sed compatible - no ? or I flags)
clean_title_for_search() {
    local title="$1"
    echo "$title" | sed -E \
        -e 's/ [Ff]rom .*//g' \
        -e 's/ [Ff]ilm [Vv]ersion//g' \
        -e 's/ [Aa]lbum [Vv]ersion//g' \
        -e 's/ [Ll]ive.*//g' \
        -e 's/ [Rr]emix.*//g' \
        -e 's/ [Ee]dit.*//g' \
        -e 's/ [Ff]eat\. .*//g' \
        -e 's/ [Ff]eaturing .*//g' \
        -e 's/ - .*[Vv]ersion//g' \
        -e 's/  +/ /g' \
        -e 's/^ *//; s/ *$//' \
        -e 's/^[([]//; s/[])]$//'
}

# Search lrclib API
search_lyrics() {
    local artist="$1"
    local album="$2"
    local title="$3"
    
    local response
    response="$(curl -sG \
        --data-urlencode "artist_name=${artist}" \
        --data-urlencode "track_name=${title}" \
        --data-urlencode "album_name=${album}" \
        "$LRCLIB_API" 2>/dev/null || true)"
    
    if [ -z "$response" ]; then
        return 1
    fi
    
    local lyrics
    lyrics="$(echo "$response" | jq -r '.syncedLyrics // .plainLyrics // empty' 2>/dev/null || true)"
    
    if [ -n "$lyrics" ] && [ "$lyrics" != "null" ]; then
        echo "$lyrics"
        return 0
    fi
    
    return 1
}

# Fetch lyrics with multiple strategies
fetch_lyrics() {
    local artist="$1"
    local album="$2"
    local title="$3"
    local out_lrc="$4"
    
    local clean_artist clean_album clean_title clean_title_api
    clean_artist="$(clean_for_api "$artist")"
    clean_album="$(clean_for_api "$album")"
    clean_title="$(clean_title_for_search "$title")"
    clean_title_api="$(clean_for_api "$clean_title")"
    
    local lyrics=""
    local strategy=""
    
    # Strategy 1: Artist + Album + Title
    if [ -n "$clean_artist" ] && [ -n "$clean_album" ] && [ -n "$clean_title_api" ]; then
        lyrics="$(search_lyrics "$clean_artist" "$clean_album" "$clean_title_api")" && strategy="artist+album+title"
    fi
    
    # Strategy 2: Artist + Title
    if [ -z "$lyrics" ] && [ -n "$clean_artist" ] && [ -n "$clean_title_api" ]; then
        lyrics="$(search_lyrics "$clean_artist" "" "$clean_title_api")" && strategy="artist+title"
    fi
    
    # Strategy 3: Title only
    if [ -z "$lyrics" ] && [ -n "$clean_title_api" ]; then
        lyrics="$(search_lyrics "" "" "$clean_title_api")" && strategy="title only"
    fi
    
    # Strategy 4: Original title
    if [ -z "$lyrics" ] && [ -n "$clean_artist" ]; then
        lyrics="$(search_lyrics "$clean_artist" "$clean_album" "$title")" && strategy="original title"
    fi
    
    # Strategy 5: Artist without "The"
    if [ -z "$lyrics" ] && [ -n "$clean_artist" ]; then
        local artist_no_the
        artist_no_the="$(echo "$clean_artist" | sed 's/^[Tt]he //g')"
        lyrics="$(search_lyrics "$artist_no_the" "$clean_album" "$clean_title_api")" && strategy="artist (no The)"
    fi
    
    if [ -n "$lyrics" ] && [ "$lyrics" != "null" ]; then
        echo "$lyrics" | sed -E '/^\[(ar|al|ti):/d' > "$out_lrc"
        log_success "Found: \"$title\" by \"$artist\" ($strategy)"
        return 0
    fi
    
    log_error "No lyrics: \"$title\" by \"$artist\""
    return 1
}

# Extract title from filename (macOS compatible)
extract_title_from_filename() {
    local filename="$1"
    local title="$filename"
    
    # Remove track number prefixes
    title="$(echo "$title" | sed -E 's/^[0-9]+[-._][0-9]+[-._]? *//')"
    title="$(echo "$title" | sed -E 's/^[0-9]+\. *//')"
    
    # If has " - ", take last part
    if echo "$title" | grep -q ' - '; then
        title="$(echo "$title" | sed -E 's/.* - //')"
    fi
    
    # Remove track numbers again
    title="$(echo "$title" | sed -E 's/^[0-9]+[-._][0-9]+[-._]? *//')"
    
    # Remove parentheses content (macOS compatible)
    title="$(echo "$title" | sed -E 's/ *\([^)]*\)//g')"
    title="$(echo "$title" | sed -E 's/ *\[[^]]*\]//g')"
    
    # Trim
    title="$(echo "$title" | sed -E 's/^ *//; s/ *$//')"
    
    echo "$title"
}

# Process single album - outputs ONLY numbers to stdout, logs to stderr
process_album() {
    local album_dir="$1"
    local lyrics_dir="$2"
    
    [ ! -d "$album_dir" ] && { echo "0|0|0"; return 1; }
    
    local artist album_name
    artist="$(basename "$(dirname "$album_dir")")"
    album_name="$(basename "$album_dir")"
    
    # Skip special directories
    case "$artist" in
        Artists|Compilations|Soundtracks|Unsorted) echo "0|0|0"; return 0 ;;
    esac
    
    local artist_lyrics_dir="$lyrics_dir/$artist"
    mkdir -p "$artist_lyrics_dir"
    
    local found=0
    local not_found=0
    local skipped=0
    
    log_info "Processing: $artist / $album_name"
    
    # Use find instead of glob
    while IFS= read -r -d '' audio_file; do
        [ -e "$audio_file" ] || continue
        
        # Get metadata
        local meta_artist meta_album meta_title meta_track
        meta_artist="$(get_metadata "$audio_file" "artist")"
        meta_album="$(get_metadata "$audio_file" "album")"
        meta_title="$(get_metadata "$audio_file" "title")"
        meta_track="$(get_metadata "$audio_file" "track")"
        
        # Fallback to filename
        if [ -z "$meta_artist" ] || [ -z "$meta_title" ]; then
            local filename
            filename="$(basename "$audio_file")"
            local name_no_ext="${filename%.*}"
            
            [ -z "$meta_artist" ] && meta_artist="$artist"
            [ -z "$meta_title" ] && meta_title="$(extract_title_from_filename "$name_no_ext")"
        fi
        
        [ -n "$meta_album" ] && album_name="$meta_album"
        
        # Clean title for filename
        local clean_title
        clean_title="$(clean_title_for_search "$meta_title")"
        [ -z "$clean_title" ] && clean_title="$(echo "$meta_title" | sed 's/[^a-zA-Z0-9 ]//g')"
        [ -z "$clean_title" ] && clean_title="unknown"
        
        local lrc_file="$artist_lyrics_dir/${clean_title}.lrc"
        
        if [ -f "$lrc_file" ]; then
            echo "  – Skipping: \"$meta_title\" (already exists)" >&2
            skipped=$((skipped + 1))
            continue
        fi
        
        if fetch_lyrics "$meta_artist" "$album_name" "$meta_title" "$lrc_file"; then
            found=$((found + 1))
        else
            not_found=$((not_found + 1))
        fi
        
        sleep "$RATE_LIMIT_DELAY"
    done < <(find "$album_dir" -maxdepth 1 -type f \( -name "*.flac" -o -name "*.m4a" -o -name "*.mp3" -o -name "*.opus" \) -print0 2>/dev/null)
    
    echo >&2
    echo "  ┌─────────────────────────────────────┐" >&2
    echo "  │ Found: $found | Not found: $not_found | Skipped: $skipped │" >&2
    echo "  └─────────────────────────────────────┘" >&2
    echo >&2
    
    # ONLY output numbers to stdout
    echo "$found|$not_found|$skipped"
}

# Process entire library
process_library() {
    local music_dir="$1"
    local lyrics_dir="$2"
    
    log_info "Scanning library: $music_dir"
    echo >&2
    
    local total_found=0
    local total_not_found=0
    local total_skipped=0
    local album_count=0
    
    # Process Artists folder
    if [ -d "$music_dir/Artists" ]; then
        while IFS= read -r -d '' artist_dir; do
            while IFS= read -r -d '' album_dir; do
                result="$(process_album "$album_dir" "$lyrics_dir")"
                IFS='|' read -r f nf s <<< "$result"
                total_found=$((total_found + f))
                total_not_found=$((total_not_found + nf))
                total_skipped=$((total_skipped + s))
                album_count=$((album_count + 1))
            done < <(find "$artist_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
        done < <(find "$music_dir/Artists" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    # Process Soundtracks folder
    if [ -d "$music_dir/Soundtracks" ]; then
        while IFS= read -r -d '' album_dir; do
            result="$(process_album "$album_dir" "$lyrics_dir")"
            IFS='|' read -r f nf s <<< "$result"
            total_found=$((total_found + f))
            total_not_found=$((total_not_found + nf))
            total_skipped=$((total_skipped + s))
            album_count=$((album_count + 1))
        done < <(find "$music_dir/Soundtracks" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    # Process Compilations folder
    if [ -d "$music_dir/Compilations" ]; then
        while IFS= read -r -d '' album_dir; do
            result="$(process_album "$album_dir" "$lyrics_dir")"
            IFS='|' read -r f nf s <<< "$result"
            total_found=$((total_found + f))
            total_not_found=$((total_not_found + nf))
            total_skipped=$((total_skipped + s))
            album_count=$((album_count + 1))
        done < <(find "$music_dir/Compilations" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    local total_songs=$((total_found + total_not_found))
    local success_rate=0
    if [ $total_songs -gt 0 ]; then
        success_rate=$((total_found * 100 / total_songs))
    fi
    
    echo >&2
    echo "═══════════════════════════════════════════════════" >&2
    echo "📊 Library Summary" >&2
    echo "═══════════════════════════════════════════════════" >&2
    echo "  Albums processed:  $album_count" >&2
    echo "  Lyrics found:      $total_found" >&2
    echo "  Lyrics not found:  $total_not_found" >&2
    echo "  Lyrics skipped:    $total_skipped" >&2
    echo "  Success rate:      ${success_rate}%" >&2
    echo "═══════════════════════════════════════════════════" >&2
}

# Main
main() {
    check_dependencies
    
    echo "═══════════════════════════════════════════════════" >&2
    echo "🎵 Enhanced Lyrics Fetcher (macOS Compatible)" >&2
    echo "═══════════════════════════════════════════════════" >&2
    echo >&2
    
    if [ "${1:-}" = "--library" ]; then
        if [ $# -ne 3 ]; then
            log_error "Usage: $0 --library \"/path/to/music\" \"/path/to/lyrics\""
            exit 1
        fi
        process_library "$2" "$3"
    else
        if [ $# -ne 2 ]; then
            log_error "Usage: $0 \"/path/to/album\" \"/path/to/lyrics\""
            log_info "Or: $0 --library \"/path/to/music\" \"/path/to/lyrics\""
            exit 1
        fi
        process_album "$1" "$2"
    fi
}

main "$@" 

