#!/usr/bin/env python3
"""Manage the user's XDG autostart entries used by niri-session."""

import configparser
import json
import os
import shutil
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "Launcher/scripts"))
from get_apps import get_apps


def main():
    directory = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "autostart"
    disabled = directory / "minflair-disabled"
    command, *args = sys.argv[1:]
    if command in ("enable", "disable"):
        name, = args
        if Path(name).name != name or not name.endswith(".desktop"):
            raise ValueError("Некорректное имя записи")
        source, target = (disabled, directory) if command == "enable" else (directory, disabled)
        target.mkdir(parents=True, exist_ok=True)
        if os.path.lexists(target / name):
            raise ValueError("Запись с таким именем уже существует")
        (source / name).rename(target / name)
    elif command == "add":
        filename, = args
        if filename not in {app["desktopFile"] for app in get_apps()}:
            raise ValueError("Приложение больше не установлено")
        source = Path(filename)
        directory.mkdir(parents=True, exist_ok=True)
        if os.path.lexists(disabled / source.name):
            raise ValueError("Включите существующую запись в списке")
        with source.open("rb") as input_file, (directory / source.name).open("xb") as output_file:
            shutil.copyfileobj(input_file, output_file)
    elif command != "list":
        raise ValueError("Неизвестная команда")

    entries = []
    for folder in (directory, disabled):
        for path in folder.glob("*.desktop"):
            config = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                config.read(path, encoding="utf-8")
                entry = config["Desktop Entry"]
                if entry.getboolean("Hidden", fallback=False):
                    continue
                entries.append({"id": path.name, "name": entry.get("Name", path.stem),
                                "enabled": folder == directory})
            except (KeyError, ValueError, configparser.Error, UnicodeError):
                continue
    reserved = {path.name for folder in (directory, disabled) for path in folder.glob("*.desktop")}
    apps = [app for app in get_apps() if Path(app["desktopFile"]).name not in reserved]
    print(json.dumps({"entries": sorted(entries, key=lambda row: row["name"].casefold()), "apps": apps}))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        sys.exit(str(error))
