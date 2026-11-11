#!/bin/bash

# Export essential environment variables for Wayland/niri
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
if [ -z "$WAYLAND_DISPLAY" ]; then
  for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
    if [ -S "$sock" ]; then
      export WAYLAND_DISPLAY=$(basename "$sock")
      break
    fi
  done
  export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
fi
export XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-niri}

MODE="${1:-full}"
DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
FILENAME="$DIR/Shot-${TIMESTAMP}.png"

mkdir -p "$DIR"

# Ensure any dangling slurp instance is terminated
pkill -x slurp 2>/dev/null

play_sound() {
  local sound="/usr/share/sounds/freedesktop/stereo/screen-capture.oga"
  if [ -f "$sound" ]; then
    if command -v paplay &>/dev/null; then
      paplay "$sound" >/dev/null 2>&1 &
    elif command -v pw-play &>/dev/null; then
      pw-play "$sound" >/dev/null 2>&1 &
    fi
  fi
}

copy_and_notify() {
  if [ -f "$FILENAME" ]; then
    wl-copy <"$FILENAME"
    play_sound
  fi
}

take_screenshot() {
  local target_mode="$1"

  case "$target_mode" in
  "full")
    sleep 0.3
    grim "$FILENAME" || return 1
    ;;

  "area" | "select")
    local geom
    geom=$(slurp -d 2>/dev/null)
    if [ -z "$geom" ]; then
      return 1
    fi
    sleep 0.2
    grim -g "$geom" "$FILENAME" || return 1
    ;;

  "window")
    sleep 0.3
    local win_w win_h rounding
    # niri captures the focused window itself (no global window coordinates in its IPC)
    niri msg action screenshot-window --write-to-disk true --path "$FILENAME" || return 1
    for _ in $(seq 20); do [ -s "$FILENAME" ] && break; sleep 0.1; done
    [ -s "$FILENAME" ] || return 1
    read -r win_w win_h < <(magick identify -format '%w %h' "$FILENAME" 2>/dev/null)
    [ -n "$win_w" ] || return 1

    rounding=$(jq -r '.rounding // 10' "$HOME/.cache/quickshell/niri_prefs.json" 2>/dev/null)
    rounding=${rounding:-10}

    local conv_cmd="convert"
    if command -v magick &>/dev/null; then
      conv_cmd="magick"
    fi

    if command -v "$conv_cmd" &>/dev/null; then
      "$conv_cmd" "$FILENAME" \
        \( +clone \
        -alpha extract \
        -fill black -colorize 100 \
        -fill white \
        -draw "roundrectangle 0,0 $((win_w - 1)),$((win_h - 1)) ${rounding},${rounding}" \
        \) \
        -alpha off \
        -compose CopyOpacity \
        -composite \
        PNG32:"$FILENAME" 2>/dev/null || true
    fi
    ;;

  *)
    return 1
    ;;
  esac

  return 0
}

case "$MODE" in
"area_3s" | "3s" | "area_delay")
  delay=3
  if [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
    delay="$2"
  fi
  sleep "$delay"
  if take_screenshot "area"; then
    copy_and_notify
  fi
  ;;

"full_3s" | "full_delay" | "5s")
  delay=3
  if [ "$MODE" = "5s" ]; then
    delay=5
  elif [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
    delay="$2"
  fi
  sleep "$delay"
  if take_screenshot "full"; then
    copy_and_notify
  fi
  ;;

"clipboard")
  geom=$(slurp -d 2>/dev/null)
  if [ -n "$geom" ]; then
    sleep 0.2
    grim -g "$geom" - | wl-copy --type image/png
    play_sound
  fi
  ;;

"ocr")
  geom=$(slurp -d 2>/dev/null)
  if [ -n "$geom" ]; then
    sleep 0.2
    temp_ocr="/tmp/ocr_temp_${TIMESTAMP}.png"
    grim -g "$geom" "$temp_ocr" 2>/dev/null
    if [ -f "$temp_ocr" ]; then
      # Russian and English; ocr_fix.py takes English lines from an English-only run (see there)
      tesseract "$temp_ocr" "${temp_ocr%.png}-mixed" -l eng+rus 2>/dev/null
      tesseract "$temp_ocr" "${temp_ocr%.png}-eng" -l eng 2>/dev/null
      python3 "$(dirname "$0")/ocr_fix.py" "${temp_ocr%.png}-mixed.txt" "${temp_ocr%.png}-eng.txt" | wl-copy
      rm -f "${temp_ocr%.png}-mixed.txt" "${temp_ocr%.png}-eng.txt"
      qs ipc call osd showMessage "Текст" "Скопирован" "ocr" 2>/dev/null || true
      rm -f "$temp_ocr"
      play_sound
    fi
  fi
  ;;

*)
  if take_screenshot "$MODE"; then
    copy_and_notify
  fi
  ;;
esac
