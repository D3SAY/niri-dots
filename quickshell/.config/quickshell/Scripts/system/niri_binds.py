#!/usr/bin/env python3
"""Keybinds editor backend for Settings → Keybinds: reads and edits the binds { } block of niri's
config.kdl, one bind per line.

    niri_binds.py list                      JSON: every bind, on or commented out, with a Russian
                                            description of what it does
    niri_binds.py set-key LINE KEY NEWKEY   change the keys of the bind on LINE
    niri_binds.py toggle LINE KEY           comment the bind out (it stops working) or back in
    niri_binds.py delete LINE KEY           remove the bind
    niri_binds.py add KEY TITLE ARG...      new bind in the "Custom" section running ARG... (spawn)
    niri_binds.py move LINE KEY SECTION     move the bind to the end of SECTION (its `// Name`
                                            comment, or the Russian name `list` shows); a
                                            section that doesn't exist yet is made at the end,
                                            one left empty is removed

LINE is the 1-based line from `list` and KEY the keys it showed, so an edit made to a file that
changed in between is refused instead of hitting the wrong line. Every edit is checked with
`niri validate` before the file is written; niri reloads it on its own.

With the Russian layout on, niri matches binds by the symbol the key gives there, falling back
to the English one only for non-Latin symbols, so letters work on both layouts but the "/" key
(which gives "." in ru) doesn't. Every edit therefore also writes, after each working bind on
such a key, a twin line for the Russian symbol marked with RU_MARK; `list` hides those lines.

niri refuses a config where two working binds share keys, so a bind given keys that another
working bind already has is saved commented out, and the reply names that other line
({"conflict": LINE}); turning a bind back on while its keys are taken is refused the same way.
"""
import sys

sys.dont_write_bytecode = True

import json
import os
import re
import subprocess

CONFIG = os.environ.get("NIRI_BINDS_CONFIG", os.path.expanduser("~/.config/niri/config.kdl"))
CUSTOM_SECTION = "// Custom"
RU_MARK = "// ru layout (auto)"
# English key -> the Latin symbol the same key gives in the ru layout (xkb symbols/ru "winkeys")
RU_KEYS = {"slash": "Period"}

KEYS = r"[A-Za-z0-9_+]+"
BIND_RE = re.compile(
    r"^(?P<indent>\s*)(?P<comment>//\s*)?(?P<key>" + KEYS + r")"
    r"(?P<props>(?:\s+[a-z-]+=(?:\"[^\"]*\"|\S+))*)\s*\{\s*(?P<body>.*?)\s*;?\s*\}\s*(?://.*)?$"
)
TITLE_RE = re.compile(r'hotkey-overlay-title="([^"]*)"')
SECTION_RE = re.compile(r"^\s*//\s*(.+?)\s*$")

SECTIONS = {
    "Media": "Медиа",
    "Quickshell": "Панели оболочки",
    "System": "Система",
    "Screenshots": "Скриншоты",
    "Apps": "Приложения",
    "Focus (vim keys and arrows)": "Фокус (vim-клавиши и стрелки)",
    "Move": "Перемещение",
    "Monitors": "Мониторы",
    "Mouse wheel": "Колесо мыши",
    "Workspaces": "Рабочие столы",
    "Columns and tabs": "Колонки и вкладки",
    "Window size and mode": "Размер и режим окна",
    "Custom": "Свои комбинации",
}

WIDGETS = {
    "minflair_keybinds": "Показать шпаргалку по горячим клавишам",
    "launcher": "Открыть лаунчер приложений",
    "clipboard": "Открыть историю буфера обмена",
    "notificationsCenter": "Открыть центр уведомлений",
    "notes": "Открыть блокнот справа",
    "wallpaper": "Открыть выбор обоев",
    "powerMenu": "Открыть меню питания (выключение, перезагрузка, выход)",
    "minflair_settings": "Открыть настройки оболочки",
    "controlCenter": "Открыть центр управления (звук, сеть, Bluetooth, zapret)",
    "dashboard": "Открыть дашборд слева",
    "music": "Открыть музыкальный плеер",
    "packagemanager": "Открыть менеджер пакетов",
    "screenshot": "Открыть панель скриншотов и записи экрана",
    "vpn": "Открыть список VPN-конфигов",
    "calendar": "Открыть календарь",
}

SCRIPTS = {
    "volume.sh up": "Сделать звук громче",
    "volume.sh down": "Сделать звук тише",
    "volume.sh mute": "Выключить или включить звук",
    "mic-toggle.sh": "Выключить или включить микрофон",
    "brightness.sh up": "Сделать экран ярче",
    "brightness.sh down": "Сделать экран темнее",
    "zapret-toggle.sh": "Включить или выключить zapret",
    "vpn.sh toggle": "Включить или выключить VPN",
}

APPS = {
    "ghostty": "терминал Ghostty",
    "helium-browser": "браузер Helium",
    "nautilus": "файловый менеджер Nautilus",
    "loaf": "файловый менеджер Loaf",
    "spotify": "Spotify",
    "telegram": "Telegram",
    "vesktop": "Discord (Vesktop)",
    "zen-browser": "браузер Zen",
    "pavucontrol": "микшер громкости (pavucontrol)",
    "normcap": "распознавание текста с экрана (normcap)",
    "playerctl": None,
}

ACTIONS = {
    "show-hotkey-overlay": "Показать подсказку niri со всеми горячими клавишами",
    "toggle-overview": "Обзор: все рабочие столы и окна сразу",
    "close-window": "Закрыть активное окно",
    "toggle-keyboard-shortcuts-inhibit": "Разрешить или запретить приложению перехватывать горячие клавиши (для игр и удалённого рабочего стола)",
    "quit": "Выйти из сессии niri",
    "screenshot": "Скриншот выделенной области (niri)",
    "screenshot-screen": "Скриншот всего экрана (niri)",
    "screenshot-window": "Скриншот активного окна (niri)",
    "focus-column-left": "Перейти к колонке слева",
    "focus-column-right": "Перейти к колонке справа",
    "focus-window-or-workspace-down": "Перейти к окну ниже, а если его нет — на рабочий стол ниже",
    "focus-window-or-workspace-up": "Перейти к окну выше, а если его нет — на рабочий стол выше",
    "move-column-left": "Передвинуть колонку влево",
    "move-column-right": "Передвинуть колонку вправо",
    "move-window-down-or-to-workspace-down": "Передвинуть окно вниз, а с края — на рабочий стол ниже",
    "move-window-up-or-to-workspace-up": "Передвинуть окно вверх, а с края — на рабочий стол выше",
    "focus-monitor-left": "Перейти на монитор слева",
    "focus-monitor-right": "Перейти на монитор справа",
    "move-column-to-monitor-left": "Перенести колонку на монитор слева",
    "move-column-to-monitor-right": "Перенести колонку на монитор справа",
    "focus-workspace-down": "Перейти на рабочий стол ниже",
    "focus-workspace-up": "Перейти на рабочий стол выше",
    "move-window-to-workspace-down": "Перенести окно на рабочий стол ниже",
    "move-window-to-workspace-up": "Перенести окно на рабочий стол выше",
    "consume-or-expel-window-left": "Забрать окно в колонку слева или вынуть его из колонки",
    "consume-or-expel-window-right": "Забрать окно в колонку справа или вынуть его из колонки",
    "toggle-column-tabbed-display": "Показывать окна колонки вкладками или друг под другом",
    "maximize-column": "Развернуть колонку на всю ширину",
    "fullscreen-window": "Окно на весь экран",
    "expand-column-to-available-width": "Растянуть колонку на всё свободное место",
    "center-column": "Поставить колонку по центру экрана",
    "reset-window-height": "Вернуть окну обычную высоту",
    "toggle-window-floating": "Сделать окно плавающим или вернуть в сетку",
    "switch-focus-between-floating-and-tiling": "Переключить фокус между плавающими окнами и сеткой",
    "power-off-monitors": "Выключить мониторы",
    "focus-column-first": "Перейти к первой колонке",
    "focus-column-last": "Перейти к последней колонке",
}


def describe(body, title):
    """What the bind does, in Russian."""
    body = body.strip().rstrip(";").strip()
    words = body.split()
    action = words[0] if words else ""
    args = re.findall(r'"([^"]*)"', body)
    rest = body[len(action):].strip()

    if action in ("spawn", "spawn-sh"):
        if action == "spawn-sh" and args:
            args = args[0].split()
        if args[:4] == ["qs", "ipc", "call", "widgets"] and len(args) > 5:
            return WIDGETS.get(args[5], "Открыть панель «" + args[5] + "»")
        if args[:5] == ["qs", "ipc", "call", "lockScreen", "lock"]:
            if "suspend" in body:
                return "Заблокировать экран и уйти в сон"
            return "Заблокировать экран"
        joined = " ".join(args)
        for script, text in SCRIPTS.items():
            if script in joined:
                return text
        if args and args[0] == "playerctl":
            return {"play-pause": "Пауза или продолжить воспроизведение", "next": "Следующий трек",
                    "previous": "Предыдущий трек"}.get(args[1] if len(args) > 1 else "", "Управление плеером")
        prog = os.path.basename(args[0]) if args else ""
        name = APPS.get(prog.lower())
        if name:
            return "Открыть " + name
        if title:
            return "Открыть " + title
        return "Запустить: " + (joined or rest)

    if action == "focus-workspace" and rest:
        return "Перейти на рабочий стол " + rest.strip('"')
    if action == "move-column-to-workspace" and rest:
        return "Перенести колонку на рабочий стол " + rest.strip('"')
    if action == "move-window-to-workspace" and rest:
        return "Перенести окно на рабочий стол " + rest.strip('"')
    if action in ("set-column-width", "set-window-height") and args:
        what = "колонку шире" if action == "set-column-width" else "окно выше"
        less = "колонку уже" if action == "set-column-width" else "окно ниже"
        val = args[0]
        return ("Сделать " + (less if val.startswith("-") else what) + " на " + val.lstrip("+-"))
    if action == "switch-layout":
        return "Переключить раскладку клавиатуры"
    if action in ACTIONS:
        return ACTIONS[action]
    if title:
        return title
    return "Действие niri: " + body


def read_lines():
    with open(CONFIG) as f:
        return f.read().split("\n")


def binds_range(lines):
    """Indexes of the lines inside `binds {` ... `}`."""
    start = next(i for i, l in enumerate(lines) if re.match(r"^binds\s*\{", l))
    end = next(i for i in range(start + 1, len(lines)) if re.match(r"^\}", lines[i]))
    return start, end


def parse(lines):
    start, end = binds_range(lines)
    section = ""
    out = []
    for i in range(start + 1, end):
        line = lines[i]
        if line.rstrip().endswith(RU_MARK):
            continue
        m = BIND_RE.match(line)
        if m:
            title_m = TITLE_RE.search(m.group("props") or "")
            title = title_m.group(1) if title_m else ""
            out.append({
                "line": i + 1,
                "key": m.group("key"),
                "enabled": m.group("comment") is None,
                "props": (m.group("props") or "").strip(),
                "body": m.group("body"),
                "title": title,
                "desc": describe(m.group("body"), title),
                "section": SECTIONS.get(section, section),
                "custom": section == "Custom",
            })
            continue
        s = SECTION_RE.match(line)
        if s and "{" not in line:
            section = s.group(1)
    return out


def section_headers(lines):
    """[(index, name)] of the `// Name` comments that start sections in binds { }."""
    start, end = binds_range(lines)
    out = []
    for i in range(start + 1, end):
        if BIND_RE.match(lines[i]):
            continue
        s = SECTION_RE.match(lines[i])
        if s and "{" not in lines[i]:
            out.append((i, s.group(1)))
    return out


def section_span(lines, header_idx):
    """Lines after a section header up to the next header or the end of binds { }."""
    start, end = binds_range(lines)
    nxt = [i for i, _ in section_headers(lines) if i > header_idx]
    return header_idx + 1, (nxt[0] if nxt else end)


def drop_empty_section(lines, header_idx):
    a, b = section_span(lines, header_idx)
    if any(BIND_RE.match(lines[i]) for i in range(a, b)):
        return
    del lines[header_idx]
    # and the blank line that separated it
    if header_idx > 0 and lines[header_idx - 1].strip() == "":
        del lines[header_idx - 1]


def move_to_section(lines, idx, target):
    reverse = {ru: en for en, ru in SECTIONS.items()}
    target = target.strip()
    if not target:
        fail("Не указана категория")
    raw = reverse.get(target, target)
    line = lines.pop(idx)
    # the section the bind came from, if this left it empty
    before = [i for i, _ in section_headers(lines) if i < idx]
    if before:
        drop_empty_section(lines, before[-1])
    header = next((i for i, n in section_headers(lines) if n == raw or SECTIONS.get(n) == target), None)
    start, end = binds_range(lines)
    if header is None:
        while end > start + 1 and lines[end - 1].strip() == "":
            end -= 1
        lines[end:end] = ["", "    // " + raw, line]
        return line
    a, b = section_span(lines, header)
    at = b
    while at > a and lines[at - 1].strip() == "":
        at -= 1
    lines.insert(at, line)
    return line


MODIFIERS = {"mod": "mod", "super": "mod", "win": "mod", "ctrl": "ctrl", "control": "ctrl",
             "shift": "shift", "alt": "alt", "iso_level3_shift": "mod5", "mod5": "mod5"}


def norm_key(key):
    """Keys as niri compares them: modifiers in any order, any case."""
    parts = key.split("+")
    mods = sorted(MODIFIERS.get(p.lower(), p.lower()) for p in parts[:-1])
    return "+".join(mods + [parts[-1].lower()])


def taken_by(lines, key, skip_idx):
    """1-based line of a working bind (other than skip_idx) with the same keys, or None."""
    want = norm_key(key)
    start, end = binds_range(lines)
    for i in range(start + 1, end):
        if i == skip_idx or lines[i].rstrip().endswith(RU_MARK):
            continue
        m = BIND_RE.match(lines[i])
        if m and m.group("comment") is None and norm_key(m.group("key")) == want:
            return i + 1
    return None


def sync_ru_aliases(lines):
    """Drop the old Russian-layout twins and write them again for the binds as they are now."""
    start, end = binds_range(lines)
    kept = [l for l in lines[start + 1:end] if not l.rstrip().endswith(RU_MARK)]
    used = set()
    for line in kept:
        m = BIND_RE.match(line)
        if m and m.group("comment") is None:
            used.add(norm_key(m.group("key")))
    body = []
    for line in kept:
        body.append(line)
        m = BIND_RE.match(line)
        if not m or m.group("comment") is not None:
            continue
        parts = m.group("key").split("+")
        ru = RU_KEYS.get(parts[-1].lower())
        if not ru:
            continue
        alias = "+".join(parts[:-1] + [ru])
        # skip it when the Russian keys already do something else
        if norm_key(alias) in used:
            continue
        used.add(norm_key(alias))
        s, e = m.span("key")
        body.append(line[:s] + alias + line[e:].rstrip() + "  " + RU_MARK)
    lines[start + 1:end] = body


def commented(line):
    m = BIND_RE.match(line)
    if not m or m.group("comment") is not None:
        return line
    return m.group("indent") + "// " + line[len(m.group("indent")):]


def write_checked(lines):
    """Validate the edited config next to the real one (the includes are relative), then save."""
    sync_ru_aliases(lines)
    text = "\n".join(lines)
    check = os.path.join(os.path.dirname(CONFIG), ".binds-check.kdl")
    with open(check, "w") as f:
        f.write(text)
    try:
        r = subprocess.run(["niri", "validate", "-c", check], capture_output=True, text=True)
    finally:
        os.unlink(check)
    if r.returncode != 0:
        err = re.sub(r"\x1b\[[0-9;]*m", "", r.stderr or r.stdout)
        msgs = re.findall(r"×\s*(.+)", err)
        fail("niri не принял изменение: " + (msgs[-1].strip() if msgs else "ошибка в конфиге"))
    real = os.path.realpath(CONFIG)
    tmp = real + ".new"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, real)


def fail(msg):
    print(json.dumps({"ok": False, "error": msg}, ensure_ascii=False))
    sys.exit(1)


def find(lines, line_no, key):
    idx = int(line_no) - 1
    m = BIND_RE.match(lines[idx]) if 0 <= idx < len(lines) else None
    if not m or m.group("key") != key:
        fail("Конфиг изменился, обновите список")
    return idx, m


def valid_key(key):
    if not re.fullmatch(KEYS, key) or key.endswith("+") or "++" in key:
        fail("Неверная комбинация: " + key)


def kdl_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    lines = read_lines()

    if cmd == "sync":
        write_checked(lines)
        print(json.dumps({"ok": True}, ensure_ascii=False))
        return

    if cmd == "list":
        sections = [SECTIONS.get(n, n) for _, n in section_headers(lines)]
        if SECTIONS["Custom"] not in sections:
            sections.append(SECTIONS["Custom"])
        print(json.dumps({"ok": True, "binds": parse(lines), "sections": sections}, ensure_ascii=False))
        return

    if cmd == "move":
        _, line_no, key, target = sys.argv[1:5]
        idx, _m = find(lines, line_no, key)
        moved = move_to_section(lines, idx, target)
        write_checked(lines)
        print(json.dumps({"ok": True, "conflict": None, "line": lines.index(moved) + 1}, ensure_ascii=False))
        return

    conflict = None
    if cmd == "set-key":
        _, line_no, key, new = sys.argv[1:5]
        valid_key(new)
        idx, m = find(lines, line_no, key)
        s, e = m.span("key")
        lines[idx] = lines[idx][:s] + new + lines[idx][e:]
        if m.group("comment") is None:
            conflict = taken_by(lines, new, idx)
            if conflict:
                lines[idx] = commented(lines[idx])
    elif cmd == "toggle":
        _, line_no, key = sys.argv[1:4]
        idx, m = find(lines, line_no, key)
        if m.group("comment") is not None:
            other = taken_by(lines, key, idx)
            if other:
                print(json.dumps({"ok": False, "conflict": other,
                                  "error": "Эта комбинация уже занята, сначала отключите или измените другую"},
                                 ensure_ascii=False))
                sys.exit(1)
            lines[idx] = m.group("indent") + lines[idx][m.end("comment"):]
        else:
            lines[idx] = commented(lines[idx])
    elif cmd == "delete":
        _, line_no, key = sys.argv[1:4]
        idx, _m = find(lines, line_no, key)
        del lines[idx]
    elif cmd == "add":
        key, title, args = sys.argv[2], sys.argv[3], sys.argv[4:]
        valid_key(key)
        if not args or not args[0].strip():
            fail("Не указана команда")
        props = (" hotkey-overlay-title=" + kdl_string(title)) if title.strip() else ""
        new = "    " + key + props + " { spawn " + " ".join(kdl_string(a) for a in args) + "; }"
        conflict = taken_by(lines, key, -1)
        if conflict:
            new = commented(new)
        start, end = binds_range(lines)
        sec = next((i for i in range(start + 1, end) if lines[i].strip() == CUSTOM_SECTION), None)
        if sec is None:
            lines[end:end] = ["", "    " + CUSTOM_SECTION, new]
        else:
            # after the last bind of the section
            at = sec + 1
            while at < end and BIND_RE.match(lines[at]):
                at += 1
            lines.insert(at, new)
    else:
        fail("unknown command " + cmd)

    # the twins written on save can move lines, so find the other bind again by its text
    other = lines[conflict - 1] if conflict else None
    write_checked(lines)
    conflict = lines.index(other) + 1 if other in lines else None
    print(json.dumps({"ok": True, "conflict": conflict}, ensure_ascii=False))


if __name__ == "__main__":
    main()
