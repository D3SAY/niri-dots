#!/usr/bin/env bash
# Autologin (greetd initial_session, see ~/niri-dots/system/greetd) starts the desktop without a
# password and marks it with MINFLAIR_AUTOLOGIN=1; this locks it at once with the Quickshell lock
# screen, so the password is typed there and unlocking shows the desktop with no black screen.
# If the lock isn't confirmed within 10 s (the shell failed to start), the session is closed and
# greetd falls back to the login screen, so the desktop never stays open without a password.

[[ $MINFLAIR_AUTOLOGIN == 1 ]] || exit 0
# the mark lives in the systemd user environment; a later login with the password mustn't see it
systemctl --user unset-environment MINFLAIR_AUTOLOGIN

# unlock in English, like hypridle's lock_cmd
niri msg action switch-layout 0

for _ in $(seq 100); do
    qs ipc call lockScreen lock >/dev/null 2>&1
    [[ $(qs ipc call lockScreen isSecure 2>/dev/null) == true ]] && exit 0
    sleep 0.1
done

notify-send -u critical "Автовход" "Экран блокировки не запустился, выхожу из сеанса" 2>/dev/null
niri msg action quit --skip-confirmation
