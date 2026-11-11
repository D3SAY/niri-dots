#!/bin/bash
# niri port: layouts come from niri's xkb config (us,ru); switch to the next one and show it
niri msg action switch-layout next || exit 1
sleep 0.1
NAME=$(niri msg -j keyboard-layouts | jq -r '.names[.current_idx]')
qs ipc call osd showMessage "Раскладка" "$NAME" "keyboard" 2>/dev/null || true
