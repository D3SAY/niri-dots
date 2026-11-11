#!/usr/bin/env python3
"""Installed Steam games that are ready to launch, as JSON: [{id, name, lastPlayed, art}],
most recently played first. Reads the app manifests of every Steam library; no network."""
import glob
import json
import os
import re

STEAM = os.path.expanduser("~/.local/share/Steam")
# compatibility layers, runtimes and redistributables are apps too, but not games
TOOLS = re.compile(r"^(Proton|Steam Linux Runtime|Steamworks Common|SteamVR)", re.I)
# StateFlags: 4 = fully installed; any other bit means updating, downloading, validating...
READY = 4


def libraries():
    paths = [STEAM]
    try:
        with open(os.path.join(STEAM, "steamapps", "libraryfolders.vdf"), encoding="utf-8") as f:
            paths += re.findall(r'"path"\s+"([^"]+)"', f.read())
    except OSError:
        pass
    seen = []
    for p in paths:
        p = os.path.realpath(p.replace("\\\\", "\\"))
        if p not in seen:
            seen.append(p)
    return seen


def field(text, name):
    m = re.search(rf'^\s*"{name}"\s+"([^"]*)"', text, re.M | re.I)
    return m.group(1) if m else ""


def art(appid):
    cache = os.path.join(STEAM, "appcache", "librarycache", appid)
    for pattern in ("library_600x900.jpg", "**/library_600x900*.jpg", "header.jpg", "**/header*.jpg"):
        found = glob.glob(os.path.join(cache, pattern), recursive=True)
        if found:
            return found[0]
    return ""


def main():
    games = {}
    for lib in libraries():
        for manifest in glob.glob(os.path.join(lib, "steamapps", "appmanifest_*.acf")):
            try:
                with open(manifest, encoding="utf-8", errors="replace") as f:
                    text = f.read()
            except OSError:
                continue
            appid, name = field(text, "appid"), field(text, "name")
            if not appid or not name or TOOLS.match(name):
                continue
            try:
                state = int(field(text, "StateFlags") or 0)
                last = int(field(text, "LastPlayed") or 0)
            except ValueError:
                continue
            if state != READY:
                continue
            games[appid] = {"id": appid, "name": name, "lastPlayed": last, "art": art(appid)}
    out = sorted(games.values(), key=lambda g: (-g["lastPlayed"], g["name"].lower()))
    print(json.dumps(out, ensure_ascii=False))


if __name__ == "__main__":
    main()
