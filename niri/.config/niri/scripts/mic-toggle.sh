#!/usr/bin/env bash
# Toggle the default microphone and show the new state in Quickshell's OSD

# Read the state first and set it explicitly: get-volume right after
# "set-mute toggle" can still report the old state
# wpctl output is parsed below: dot decimals whatever the locale
export LC_ALL=C.UTF-8
src=@DEFAULT_AUDIO_SOURCE@
if wpctl get-volume "$src" | grep -q MUTED; then
    wpctl set-mute "$src" 0
    muted=false
else
    wpctl set-mute "$src" 1
    muted=true
fi
percent=$(wpctl get-volume "$src" | awk '{ printf "%d", $2 * 100 + 0.5 }')
qs ipc call osd showMic "$percent" "$muted"
