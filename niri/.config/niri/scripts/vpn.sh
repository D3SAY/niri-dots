#!/usr/bin/env bash
# AmneziaWG VPN for the Quickshell VPN button: configs are ~/.config/awg/<name>.conf (plain
# WireGuard configs work too), the interface is named after the file.
#   vpn.sh list          one line per config: <name> <1 if connected, else 0>
#   vpn.sh up <name>     connect to <name>, dropping any other config that's up
#   vpn.sh down          disconnect
#   vpn.sh toggle        disconnect if up, else connect to the last used config (or the first one)
# awg-quick needs root: up/down go through the optional helper with polkit authentication.

dir=$HOME/.config/awg
helper=/usr/local/lib/minflair/minflair-helper
last_file=${XDG_STATE_HOME:-$HOME/.local/state}/minflair/vpn-last

configs() {
    for f in "$1"/*.conf; do
        [[ -f $f ]] && basename "$f" .conf
    done
}

# the config that's up now, if any
active() {
    for n in $(configs "$dir"); do
        [[ -d /sys/class/net/$n ]] && echo "$n" && return
    done
}

remember() {
    mkdir -p "$(dirname "$last_file")" && echo "$1" >"$last_file"
}

if [[ $1 == toggle ]]; then
    cur=$(active)
    if [[ -n $cur ]]; then
        set -- down
    else
        last=$(cat "$last_file" 2>/dev/null)
        [[ -f $dir/$last.conf ]] || last=$(configs "$dir" | head -n 1)
        [[ -n $last ]] || { notify-send -i network-vpn-symbolic "VPN" "Нет конфигов в $dir"; exit 1; }
        set -- up "$last"
    fi
fi

case $1 in
list)
    cur=$(active)
    # a config brought up some other way (awg-quick by hand) counts as the last used too
    [[ -n $cur && $cur != "$(cat "$last_file" 2>/dev/null)" ]] && remember "$cur"
    for n in $(configs "$dir"); do
        [[ $n == "$cur" ]] && echo "$n 1" || echo "$n 0"
    done
    ;;
up | down)
    name=$([[ $1 == up ]] && echo "$2")
    if [[ $1 == up && ! -f $dir/$name.conf ]]; then
        notify-send -u critical -i network-vpn-symbolic "VPN" "Нет конфига $dir/$name.conf"
        exit 1
    fi
    if [[ ! -x $helper ]]; then
        notify-send -u critical -i dialog-error-symbolic "VPN" "Установите помощник: sudo ./system/install.sh --network-helper"
        exit 1
    fi
    err=$(pkexec "$helper" vpn "$1" $name 2>&1 >/dev/null)
    code=$?
    # 126/127: the password prompt was cancelled
    if ((code == 126 || code == 127)); then
        exit "$code"
    elif ((code != 0)); then
        notify-send -u critical -i network-vpn-disconnected-symbolic "VPN" "Ошибка: $(tail -n 1 <<<"$err")"
    elif [[ -n $name ]]; then
        remember "$name"
        notify-send -i network-vpn-symbolic "VPN" "Подключено: $name"
    else
        notify-send -i network-vpn-disconnected-symbolic "VPN" "Отключено"
    fi
    exit "$code"
    ;;
*)
    echo "usage: vpn.sh list | up <name> | down | toggle" >&2
    exit 2
    ;;
esac
