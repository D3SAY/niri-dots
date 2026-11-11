#!/usr/bin/env python3
"""Keybinds for the cheat sheet, read from niri's config.kdl.

Sections come from the `// Name` comments inside `binds { }`. Section names and descriptions are
the Russian ones of the Keybinds settings page (Scripts/system/niri_binds.py). Prints
[{"section": ..., "binds": [{"keys": [...], "desc": ...}]}] like the original.
"""
import sys

sys.dont_write_bytecode = True

import json
import re
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "Scripts" / "system"))
from niri_binds import SECTIONS, describe  # noqa: E402

KEY_MAP = {
    "Mod": "Super",
    "Return": "Enter",
    "Space": "Space",
    "Left": "←",
    "Right": "→",
    "Up": "↑",
    "Down": "↓",
    "Slash": "/",
    "BracketLeft": "[",
    "BracketRight": "]",
    "Escape": "Esc",
    "Print": "PrtSc",
    "WheelScrollDown": "Колесо ↓",
    "WheelScrollUp": "Колесо ↑",
    "XF86AudioRaiseVolume": "Громк. ↑",
    "XF86AudioLowerVolume": "Громк. ↓",
    "XF86AudioMute": "Без звука",
    "XF86AudioMicMute": "Микрофон",
    "XF86MonBrightnessUp": "Ярк. ↑",
    "XF86MonBrightnessDown": "Ярк. ↓",
    "XF86AudioPlay": "Пуск/пауза",
}

BIND_RE = re.compile(r"^\s*([A-Za-z0-9_+]+)((?:\s+[a-z-]+=(?:\"[^\"]*\"|\S+))*)\s*\{\s*(.*?)\s*;?\s*\}\s*$")
TITLE_RE = re.compile(r'hotkey-overlay-title="([^"]*)"')


def parse_keybinds(conf):
    try:
        lines = Path(conf).read_text().splitlines()
    except OSError:
        print("[]")
        return

    sections = []
    current = None
    in_binds = False
    for line in lines:
        if not in_binds:
            if re.match(r"^binds\s*\{", line):
                in_binds = True
            continue
        if re.match(r"^\}", line):
            break
        # Russian-layout twins written by Scripts/system/niri_binds.py: the same bind again
        if line.rstrip().endswith("// ru layout (auto)"):
            continue
        comment = re.match(r"^\s*//\s*(.+)$", line)
        # a bind switched off in Settings is commented out, not a section header
        if comment and BIND_RE.match(comment.group(1)):
            continue
        if comment:
            name = comment.group(1).strip()
            current = {"section": SECTIONS.get(name, name), "binds": []}
            sections.append(current)
            continue
        m = BIND_RE.match(line)
        if not m:
            continue
        if current is None:
            current = {"section": "Общее", "binds": []}
            sections.append(current)
        keys = [KEY_MAP.get(k, k) for k in m.group(1).split("+")]
        title = TITLE_RE.search(m.group(2) or "")
        desc = describe(m.group(3), title.group(1) if title else "")
        current["binds"].append({"keys": keys, "desc": desc})

    print(json.dumps([s for s in sections if s["binds"]]))


if __name__ == "__main__":
    conf = str(Path.home() / ".config" / "niri" / "config.kdl")
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        conf = sys.argv[1]
    parse_keybinds(conf)
