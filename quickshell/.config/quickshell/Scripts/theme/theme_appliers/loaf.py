import json
import os

from color_utils import blend_hex, sanitize_color

# Loaf's own settings that make it follow the palette below and look like the rest of the desktop;
# only filled in while unset, so changes made in Loaf's settings stay
DEFAULTS = {
    "themeMode": "dark",
    "accentName": "wallpaper",
    "backgroundOpacity": "0.5",
    "panelOpacity": "0.6",
}


def apply(home, colors):
    """Loaf file manager: it reads a Material-style palette from ~/.cache/current_wallpaper_palette.json
    (one of the files it watches) when its accent is "wallpaper", and reloads it on change."""
    bg = sanitize_color(colors.get("opaqueBg", colors["bg"]))
    fg = sanitize_color(colors["fg"])
    accent = sanitize_color(colors["accent"])
    alt = sanitize_color(colors["accentComplementary"])

    # surfaces step up from the wallpaper background toward the text color, like the shell's cards
    palette = {
        "background": bg,
        "surface_container_lowest": blend_hex(bg, "#000000", 0.7),
        "surface_container_low": blend_hex(fg, bg, 0.035),
        "surface_container": blend_hex(fg, bg, 0.06),
        "surface_container_high": blend_hex(fg, bg, 0.09),
        "surface_container_highest": blend_hex(fg, bg, 0.12),
        "primary": accent,
        "on_primary": fg,
        "primary_container": blend_hex(accent, bg, 0.35),
        "on_primary_container": fg,
        "secondary_container": blend_hex(accent, bg, 0.18),
        "on_secondary_container": fg,
        "tertiary_container": blend_hex(alt, bg, 0.25),
        "on_surface": fg,
        "on_surface_variant": blend_hex(fg, bg, 0.6),
        "outline": blend_hex(fg, bg, 0.35),
        "outline_variant": blend_hex(fg, bg, 0.12),
    }
    cache = os.path.join(home, ".cache")
    os.makedirs(cache, exist_ok=True)
    path = os.path.join(cache, "current_wallpaper_palette.json")
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(palette, f, indent=2)
    os.replace(tmp, path)

    config_dir = os.path.join(home, ".config", "loaf")
    config = os.path.join(config_dir, "config.json")
    try:
        with open(config) as f:
            settings = json.load(f)
    except (OSError, ValueError):
        settings = {}
    missing = {k: v for k, v in DEFAULTS.items() if k not in settings}
    if missing:
        settings.update(missing)
        os.makedirs(config_dir, exist_ok=True)
        with open(config, "w") as f:
            json.dump(settings, f, indent=2)
