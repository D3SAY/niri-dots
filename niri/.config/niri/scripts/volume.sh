#!/usr/bin/env bash
# Change the output volume and show the level in Quickshell's OSD. Usage: volume.sh up|down|mute

# wpctl output is parsed below: dot decimals whatever the locale
export LC_ALL=C.UTF-8
sink=@DEFAULT_AUDIO_SINK@

case "$1" in
    up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1.0 "$sink" 0.02+ ;;
    down) wpctl set-volume "$sink" 0.02- ;;
    mute) wpctl set-mute "$sink" toggle ;;
    *)    echo "usage: $0 up|down|mute" >&2; exit 1 ;;
esac

# "Volume: 0.45" or "Volume: 0.45 [MUTED]"
state=$(wpctl get-volume "$sink")
percent=$(awk '{ printf "%d", $2 * 100 + 0.5 }' <<<"$state")
muted=$([[ $state == *MUTED* ]] && echo true || echo false)
qs ipc call osd showVolume "$percent" "$muted"
