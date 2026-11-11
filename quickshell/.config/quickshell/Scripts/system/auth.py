#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import getpass
import os

try:
    import pam
except ImportError:
    print("Error: python-pam is not installed. Please install it.")
    sys.exit(1)


def unlock_keyring(password):
    """Autologin (greetd initial_session) starts the session without a password, so the default
    keyring stays locked and apps ask for it. The password just typed on the lock screen unlocks
    it in the running gnome-keyring-daemon; this only works when the keyring has the same password
    as the account (Scripts/system/keyring_password.py sets that once)."""
    try:
        import gi

        gi.require_version("Gio", "2.0")
        from gi.repository import Gio, GLib

        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)

        def call(path, iface, method, args, reply):
            return bus.call_sync(
                "org.freedesktop.secrets", path, iface, method, args,
                GLib.VariantType(reply), Gio.DBusCallFlags.NO_AUTO_START, 5000, None,
            ).unpack()

        service = "/org/freedesktop/secrets"
        (collection,) = call(service, "org.freedesktop.Secret.Service", "ReadAlias",
                             GLib.Variant("(s)", ("default",)), "(o)")
        if collection == "/":
            return
        (locked,) = call(collection, "org.freedesktop.DBus.Properties", "Get",
                         GLib.Variant("(ss)", ("org.freedesktop.Secret.Collection", "Locked")), "(v)")
        if not locked:
            return
        _, session = call(service, "org.freedesktop.Secret.Service", "OpenSession",
                          GLib.Variant("(sv)", ("plain", GLib.Variant("s", ""))), "(vo)")
        try:
            secret = (session, b"", password.encode(), "text/plain")
            call(service, "org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface",
                 "UnlockWithMasterPassword", GLib.Variant("(o(oayays))", (collection, secret)), "()")
        finally:
            call(session, "org.freedesktop.Secret.Session", "Close", None, "()")
    except Exception:
        # wrong keyring password or no keyring daemon: apps will just ask as before
        pass


def authenticate(password):
    p = pam.pam()
    username = getpass.getuser()
    return p.authenticate(username, password)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        password = sys.argv[1]
    else:
        password = sys.stdin.readline().rstrip("\r\n")

    if authenticate(password):
        unlock_keyring(password)
        sys.exit(0)
    else:
        sys.exit(1)
