#!/usr/bin/env bash
# zapret2 (Discord, YouTube and SoundCloud without VPN): turn it on/off; the state survives reboot.
# Used by the Zapret tile in Quickshell's control center.
# It goes through the root helper from ~/niri-dots/system, which polkit lets run without a
# password; without the helper systemctl asks for it through the polkit agent (polkit-gnome).

helper=/usr/local/lib/minflair/minflair-helper
if systemctl is-active --quiet zapret2; then
    state=off
else
    state=on
fi
if [[ -x $helper ]]; then
    pkexec "$helper" zapret "$state"
elif [[ $state == on ]]; then
    systemctl enable --now zapret2
else
    systemctl disable --now zapret2
fi

# report what actually happened: the service exits right away if nfqws2 is disabled in its config
if systemctl is-active --quiet zapret2; then
    notify-send -i network-vpn-symbolic "zapret" "Включён: Discord, YouTube и SoundCloud"
elif systemctl is-enabled --quiet zapret2; then
    notify-send -u critical -i dialog-error-symbolic "zapret" \
        "Не запустился. См. раздел Zapret в README."
else
    notify-send -i network-vpn-disconnected-symbolic "zapret" "Выключен"
fi
