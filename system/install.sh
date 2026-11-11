#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo 'Usage: sudo ./system/install.sh --greetd|--autologin|--network-helper|--network-dns|--zapret|--virtual-camera'
    echo 'Each invocation configures one optional integration. --greetd uses password login.'
}

if [[ ${1:-} == --help || $# == 0 ]]; then
    usage
    exit 0
fi
if [[ $# != 1 ]]; then
    usage >&2
    exit 2
fi
case $1 in
    --greetd|--autologin|--network-helper|--network-dns|--zapret|--virtual-camera) ;;
    *) usage >&2; exit 2 ;;
esac
if [[ $EUID != 0 ]]; then
    echo 'Run this optional system step through sudo.' >&2
    exit 1
fi

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
user=${SUDO_USER:-}

install_greeter() {
    if [[ ! $user =~ ^[a-z_][a-z0-9_-]*$ || $user == root ]]; then
        echo 'Run sudo from the desktop user account.' >&2
        exit 1
    fi
    getent passwd greeter >/dev/null || { echo 'Install greetd first.' >&2; exit 1; }
    command -v niri-session >/dev/null
    command -v qs >/dev/null
    install -Dm644 "$repo/system/greetd/niri-greeter.kdl" /etc/greetd/niri-greeter.kdl
    install -Dm644 "$repo/system/greetd/minflair-greeter/shell.qml" /etc/greetd/minflair-greeter/shell.qml
    install -d -o "$user" -g "$(id -gn "$user")" -m755 /var/cache/minflair-greeter
    if [[ -f /etc/greetd/config.toml && ! -e /etc/greetd/config.toml.pre-minflair ]]; then
        cp -p -- /etc/greetd/config.toml /etc/greetd/config.toml.pre-minflair
    fi
    if [[ $1 == --autologin ]]; then
        {
            sed '/^\[initial_session\]/,$d' "$repo/system/greetd/config.toml"
            printf '\n[initial_session]\ncommand = "env MINFLAIR_AUTOLOGIN=1 niri-session"\nuser = "%s"\n' "$user"
        } | install -Dm644 /dev/stdin /etc/greetd/config.toml
    else
        install -Dm644 "$repo/system/greetd/config.toml" /etc/greetd/config.toml
    fi
    echo 'greetd configuration installed. Enable greetd separately when ready to switch display managers.'
}

case $1 in
    --greetd|--autologin)
        install_greeter "$1"
        ;;
    --network-helper)
        install -Dm755 "$repo/system/minflair-helper" /usr/local/lib/minflair/minflair-helper
        echo 'Network helper installed. Actions use standard polkit authentication.'
        ;;
    --network-dns)
        command -v nmcli >/dev/null
        command -v resolvconf >/dev/null
        install -Dm644 "$repo/system/NetworkManager/rc-manager.conf" /etc/NetworkManager/conf.d/rc-manager.conf
        nmcli general reload
        resolvconf -u
        ;;
    --zapret)
        if [[ ! -d /opt/zapret2/ipset ]]; then
            echo 'Install zapret2 first.' >&2
            exit 1
        fi
        for pair in "config" "ipset/zapret-hosts-user.txt"; do
            dest="/opt/zapret2/$pair"
            if [[ -f $dest && ! -e $dest.pre-minflair ]]; then
                cp -p -- "$dest" "$dest.pre-minflair"
            fi
            install -m644 "$repo/zapret/${pair##*/}" "$dest"
        done
        echo 'Zapret configuration installed. Restart the service separately if it is already running.'
        ;;
    --virtual-camera)
        modinfo v4l2loopback >/dev/null || { echo 'Install v4l2loopback for the running kernel first.' >&2; exit 1; }
        install -Dm644 "$repo/system/v4l2loopback/modules-load.conf" /etc/modules-load.d/v4l2loopback.conf
        install -Dm644 "$repo/system/v4l2loopback/modprobe.conf" /etc/modprobe.d/v4l2loopback.conf
        echo 'Virtual camera configuration installed for the next boot.'
        ;;
esac
