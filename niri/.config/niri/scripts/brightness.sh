#!/usr/bin/env bash
# Change the screen brightness and show the level in Quickshell's OSD. Usage: brightness.sh up|down

case "$1" in
    up)   brightnessctl -q set 5%+ ;;
    down) brightnessctl -q -n1 set 5%- ;;  # -n1 keeps the screen from going fully dark
    *)    echo "usage: $0 up|down" >&2; exit 1 ;;
esac

max=$(brightnessctl max)
(( max > 0 )) || exit 0
qs ipc call osd showBrightness "$(( $(brightnessctl get) * 100 / max ))"
