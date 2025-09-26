#!/usr/bin/env bash

set -o noclobber
set -o noglob

IFS=$'\n'
FILE_PATH="${1}"
PV_WIDTH="${2}"
PV_HEIGHT="${3}"
IMAGE_CACHE_PATH="${4}"
PV_IMAGE_ENABLED="${5}"

# Function to check if imgcat is available
has_imgcat() {
  command -v imgcat >/dev/null 2>&1
}

# Function to handle image preview with imgcat
preview_image() {
  local file="$1"
  local width="$2"

  if has_imgcat; then
    # Try imgcat with width parameter
    imgcat --width "$width" "$file" 2>/dev/null && return 0

    # If that fails, try without width parameter
    imgcat "$file" 2>/dev/null && return 0
  fi

  return 1
}

handle_extension() {
  case "${FILE_EXTENSION_LOWER}" in
  # Archive formats
  a | ace | alz | arc | arj | bz | bz2 | cab | cpio | deb | gz | jar | lha | lz | lzh | lzma | lzo | \
    rpm | rz | t7z | tar | tbz | tbz2 | tgz | tlz | txz | tZ | tzo | war | xpi | xz | Z | zip)
    atool --list -- "${FILE_PATH}" && exit 0
    exit 1
    ;;
  rar)
    unrar lt -p- -- "${FILE_PATH}" && exit 0
    exit 1
    ;;
  7z)
    7z l -p -- "${FILE_PATH}" && exit 0
    exit 1
    ;;

  # PDF
  pdf)
    if [ "${PV_IMAGE_ENABLED}" = "true" ]; then
      pdftoppm -f 1 -l 1 -jpeg -singlefile -- "${FILE_PATH}" \
        "${IMAGE_CACHE_PATH%.*}" && exit 0
    else
      pdftotext -l 10 -nopgbrk -q -- "${FILE_PATH}" - && exit 0
    fi
    exit 1
    ;;

  # Document formats
  odt | ods | odp | sxw)
    pandoc -s -t markdown -- "${FILE_PATH}" && exit 0
    exit 1
    ;;
  docx | doc)
    pandoc -s -t markdown -- "${FILE_PATH}" && exit 0
    exit 1
    ;;
  xlsx | xls)
    pandoc -s -t csv -- "${FILE_PATH}" && exit 0
    exit 1
    ;;
  pptx | ppt)
    pandoc -s -t plain -- "${FILE_PATH}" && exit 0
    exit 1
    ;;
  esac
}

handle_mime() {
  local mime_type="${1}"
  case "${mime_type}" in
  # Text files
  text/* | */xml)
    bat --color=always --style=plain --pager=never -- "${FILE_PATH}" && exit 0
    exit 1
    ;;

    # Images
    #  image/*)
    #    if [ "${PV_IMAGE_ENABLED}" = "true" ]; then
    #      preview_image "${FILE_PATH}" "${PV_WIDTH}" && exit 0
    #    fi
    #    exit 1
    #    ;;
    #
  ## Image - using iTerm2's imgcat with chafa fallback
  image/*)
    if [ "${PV_IMAGE_ENABLED}" = "true" ]; then
      if has_imgcat; then
        imgcat --width "${PV_WIDTH}" "${FILE_PATH}" && exit 0
      else
        # Fallback to chafa for terminal preview
        chafa --size="${PV_WIDTH}x${PV_HEIGHT}" -- "${FILE_PATH}" && exit 0
      fi
    fi
    exit 1
    ;;

  # Video files
  video/*)
    if [ "${PV_IMAGE_ENABLED}" = "true" ]; then
      ffmpegthumbnailer -i "${FILE_PATH}" -o "${IMAGE_CACHE_PATH}.jpg" -s 0 &&
        preview_image "${IMAGE_CACHE_PATH}.jpg" "${PV_WIDTH}" && exit 0
    fi
    exit 1
    ;;

  # PDF files
  application/pdf)
    if [ "${PV_IMAGE_ENABLED}" = "true" ]; then
      pdftoppm -f 1 -l 1 -jpeg -singlefile -- "${FILE_PATH}" \
        "${IMAGE_CACHE_PATH%.*}" &&
        preview_image "${IMAGE_CACHE_PATH%.*}.jpg" "${PV_WIDTH}" && exit 0
    else
      pdftotext -l 10 -nopgbrk -q -- "${FILE_PATH}" - && exit 0
    fi
    exit 1
    ;;

  # Office documents
  application/vnd.openxmlformats-officedocument.*)
    pandoc -s -t markdown -- "${FILE_PATH}" && exit 0
    exit 1
    ;;
  esac
}

handle_fallback() {
  echo '----- File Type Classification -----' && file --dereference --brief -- "${FILE_PATH}" && exit 1
}

FILE_EXTENSION="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER="$(printf "%s" "${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"

handle_extension
MIMETYPE="$(file --dereference --brief --mime-type -- "${FILE_PATH}")"
handle_mime "${MIMETYPE}"
handle_fallback

exit 1
