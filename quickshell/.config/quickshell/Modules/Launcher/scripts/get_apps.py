#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import configparser
import json
import os
import shlex
import shutil
from pathlib import Path


def launch_args(command):
    try:
        parts = shlex.split(command)
    except ValueError:
        return []
    return [part.replace("%%", "%") for part in parts
            if part not in ("%f", "%F", "%u", "%U", "%i", "%c", "%k",
                            "%d", "%D", "%n", "%N", "%v", "%m")]


def get_apps():
    apps = []
    seen_execs = set()

    # Search standard XDG application directories
    xdg_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    paths = [Path(p) / "applications" for p in xdg_dirs]
    paths.insert(0, Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "applications")
    paths.append(
        Path.home()
        / ".local"
        / "share"
        / "flatpak"
        / "exports"
        / "share"
        / "applications"
    )
    paths.append(Path("/var/lib/flatpak/exports/share/applications"))

    for d in paths:
        if not d.is_dir():
            continue
        for f in d.glob("*.desktop"):
            try:
                config = configparser.ConfigParser(interpolation=None)
                config.read(f, encoding="utf-8")
                if "Desktop Entry" in config:
                    entry = config["Desktop Entry"]

                    if (
                        entry.get("NoDisplay", "false").lower() == "true"
                        or entry.get("Hidden", "false").lower() == "true"
                    ):
                        continue

                    name = entry.get("Name", "").strip()
                    raw_exec = entry.get("Exec", "").strip()
                    args = launch_args(raw_exec)
                    executable = raw_exec.split(" %")[0].replace('"', "").strip()

                    # The desktop-entry specification says entries with an unavailable
                    # TryExec must be ignored. This also hides launchers left behind by
                    # an uninstalled application.
                    try_exec = entry.get("TryExec", "").replace('"', "").strip()
                    if try_exec and shutil.which(try_exec) is None:
                        continue

                    if executable.startswith("/usr/bin/"):
                        executable = executable[9:]

                    icon = entry.get("Icon", "").replace('"', "").strip()
                    terminal = entry.get("Terminal", "false").lower() == "true"

                    actions = []
                    if "Actions" in entry:
                        action_keys = entry.get("Actions", "").strip(";").split(";")
                        for ak in action_keys:
                            ak = ak.strip()
                            if not ak:
                                continue
                            action_group = f"Desktop Action {ak}"
                            if action_group in config:
                                a_entry = config[action_group]
                                a_name = a_entry.get("Name", "").strip()
                                a_exec = a_entry.get("Exec", "").strip()
                                action_args = launch_args(a_exec)
                                if a_name and action_args:
                                    actions.append(
                                        {
                                            "name": a_name,
                                            "argv": action_args,
                                        }
                                    )

                    if name and args and executable not in seen_execs:
                        apps.append(
                            {
                                "name": name,
                                "argv": args,
                                "icon": icon,
                                "terminal": terminal,
                                "actions": actions,
                                "desktopFile": str(f),
                            }
                        )
                        seen_execs.add(executable)
            except Exception:
                continue

    return sorted(apps, key=lambda x: x["name"].lower())


if __name__ == "__main__":
    print(json.dumps(get_apps()))
