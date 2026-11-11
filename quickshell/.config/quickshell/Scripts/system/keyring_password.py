#!/usr/bin/env python3
"""Give the default keyring the same password as the account, once, in a terminal:
    python3 ~/.config/quickshell/Scripts/system/keyring_password.py

After that the lock screen unlocks the keyring with the password typed there (auth.py), so apps
stop asking for it after the autologin. Nothing is printed or stored; both passwords go straight
to gnome-keyring over D-Bus.
"""
import getpass
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
SERVICE = "/org/freedesktop/secrets"
GUILT = "org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface"


def call(path, iface, method, args, reply):
    return bus.call_sync(
        "org.freedesktop.secrets", path, iface, method, args,
        GLib.VariantType(reply), Gio.DBusCallFlags.NONE, 10000, None,
    ).unpack()


def main():
    try:
        import pam
    except ImportError:
        sys.exit("python-pam is missing")

    (collection,) = call(SERVICE, "org.freedesktop.Secret.Service", "ReadAlias",
                         GLib.Variant("(s)", ("default",)), "(o)")
    if collection == "/":
        sys.exit("No default keyring")

    old = getpass.getpass("Current keyring password (empty if it has none): ")
    new = getpass.getpass("Account password (the one for the lock screen): ")
    if not pam.pam().authenticate(getpass.getuser(), new):
        sys.exit("That isn't the account password, nothing changed")

    _, session = call(SERVICE, "org.freedesktop.Secret.Service", "OpenSession",
                      GLib.Variant("(sv)", ("plain", GLib.Variant("s", ""))), "(vo)")
    try:
        secret = lambda p: (session, b"", p.encode(), "text/plain")
        call(SERVICE, GUILT, "ChangeWithMasterPassword",
             GLib.Variant("(o(oayays)(oayays))", (collection, secret(old), secret(new))), "()")
    except GLib.Error as e:
        sys.exit("gnome-keyring refused, the current keyring password is probably wrong: " + e.message)
    finally:
        call(session, "org.freedesktop.Secret.Session", "Close", None, "()")
    print("Done: the keyring now opens with the account password")


main()
