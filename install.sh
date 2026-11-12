#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Использование: ./install.sh [--dry-run] [--configs-only | --uninstall] [--gtk-theme] [--lyse]

Без опций       Установить зависимости и подключить niri, Minflair, hypridle,
                Ghostty и Fastfetch.
--dry-run       Показать недостающие пакеты и проверить ссылки без изменений.
--configs-only  Подключить конфиги, используя уже установленные зависимости.
--uninstall     Удалить ссылки Stow. Пакеты и пользовательские данные остаются.
--gtk-theme     Включить тему Material-Gnome в набор конфигов.
--lyse          Включить обёртку Lyse. Сам Lyse устанавливается отдельно.
--help          Показать справку.
EOF
}

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

dry_run=false
configs_only=false
uninstall=false
with_lyse=false
stow_packages=(niri quickshell hypr ghostty fastfetch)
for option in "$@"; do
    case "$option" in
        --dry-run) dry_run=true ;;
        --configs-only) configs_only=true ;;
        --uninstall) uninstall=true ;;
        --gtk-theme) stow_packages+=(gtk-theme) ;;
        --lyse) with_lyse=true ;;
        -h|--help) usage; exit 0 ;;
        *) fail "Неизвестная опция: $option. См. ./install.sh --help." ;;
    esac
done

if "$configs_only" && "$uninstall"; then
    fail 'Выбери только одну опцию: --configs-only или --uninstall.'
fi
if "$with_lyse"; then
    stow_packages+=(lyse)
fi
(( EUID != 0 )) || fail 'Запусти установщик от обычного пользователя. Для пакетов он вызовет sudo.'
[[ -d ${HOME:-} && $HOME = /* ]] || fail 'Нужен существующий абсолютный путь в HOME.'
[[ ${XDG_CONFIG_HOME:-$HOME/.config} = "$HOME/.config" ]] ||
    fail 'Установщик ожидает XDG_CONFIG_HOME=$HOME/.config.'

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
if [[ $repo == "$(cd -- "$HOME" && pwd -P)" ]]; then
    fail 'Храни репозиторий в отдельной папке, например ~/niri-dots.'
fi

stow_configs() (
    # Keep user Stow options such as --adopt out of installer operations.
    local clean_dir
    clean_dir=$(mktemp -d)
    trap 'rmdir -- "$clean_dir"' EXIT
    cd -- "$clean_dir"
    HOME="$clean_dir" stow --dir="$repo" --target="$HOME" --no-folding "$@" "${stow_packages[@]}"
)

if "$uninstall"; then
    command -v stow >/dev/null || fail 'Для удаления ссылок нужен GNU Stow.'
    if "$dry_run"; then
        stow_configs --simulate --verbose --delete
    else
        stow_configs --delete
        printf 'Ссылки выбранных конфигов удалены.\n'
    fi
    exit 0
fi

missing=()
if ! "$configs_only"; then
    command -v pacman >/dev/null || fail 'Для установки пакетов нужен pacman на Arch-совместимой системе.'
    dependencies=(
        stow niri quickshell xwayland-satellite qt6-5compat qt6-declarative
        qt6-imageformats qt6ct qt5ct python-pam python-pillow python-gobject jq
        libnotify awww hypridle polkit-gnome gnome-keyring xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk ghostty fastfetch playerctl pamixer pavucontrol upower
        cava wlsunset brightnessctl cliphist wl-clipboard grim slurp imagemagick
        ffmpeg wf-recorder pacman-contrib papirus-icon-theme noto-fonts noto-fonts-emoji
        ttf-cascadia-code-nerd
    )
    if absent=$(pacman -T "${dependencies[@]}"); then
        printf 'Все зависимости уже установлены.\n'
    else
        status=$?
        [[ $status == 127 && -n $absent ]] || fail 'Не удалось проверить пакеты через pacman.'
        mapfile -t missing <<< "$absent"
        printf 'Недостающие пакеты: %s\n' "${missing[*]}"
    fi
fi

if "$with_lyse" && [[ ! -x /usr/bin/lyse ]]; then
    printf 'Lyse ещё не установлен. Для текста песен установи Lyse из AUR.\n'
fi

if ! command -v stow >/dev/null; then
    if "$configs_only"; then
        fail 'Для подключения конфигов нужен GNU Stow.'
    elif "$dry_run"; then
        printf 'Проверка конфликтов доступна после установки GNU Stow.\n'
        exit 0
    fi
    sudo pacman -S --needed -- stow
fi

preview=(--simulate)
if "$dry_run"; then
    preview+=(--verbose)
fi
if ! stow_configs "${preview[@]}" --stow; then
    fail 'Ссылки не изменены. Сохрани конфликтующие файлы в резервную копию, убери их с указанных путей и повтори установку.'
fi
if "$dry_run"; then
    printf 'Предварительная проверка завершена. Конфиги не изменены.\n'
    exit 0
fi

if (( ${#missing[@]} )); then
    sudo pacman -S --needed -- "${missing[@]}"
fi
command -v niri >/dev/null || fail 'Для проверки конфигурации нужен niri.'
niri validate -c "$repo/niri/.config/niri/config.kdl"
stow_configs --stow
mkdir -p -- "$HOME/Pictures/Wallpapers"
if ! niri validate -c "$HOME/.config/niri/config.kdl"; then
    fail 'Ссылки установлены, но niri не прошёл проверку с локальными настройками. Исправь ошибку выше или запусти ./install.sh --uninstall.'
fi
printf 'Готово. Выбери niri на экране входа или запусти niri-session из TTY.\n'
