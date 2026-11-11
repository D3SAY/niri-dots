import getpass
import json
import os
import shutil
import subprocess

# readable by the login screen (greetd's "greeter" user); system/install.sh creates it for us
SHARED = "/var/cache/minflair-greeter"


def apply(home, colors):
    """Login screen: the current wallpaper, colors, user name and avatar for the greeter."""
    if not os.access(SHARED, os.W_OK):
        return

    with open(os.path.join(home, ".cache", "quickshell", "colorscheme.json")) as f:
        scheme = json.load(f)
    _write(os.path.join(SHARED, "colorscheme.json"), json.dumps(scheme))
    _write(os.path.join(SHARED, "user"), getpass.getuser() + "\n")

    wallpaper = _current_wallpaper(home)
    if wallpaper:
        # the greeter blurs it anyway, a small copy loads instantly
        tmp = os.path.join(SHARED, ".wallpaper.jpg")
        r = subprocess.run(
            ["magick", wallpaper + "[0]", "-resize", "960x540^", "-quality", "85", tmp],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if r.returncode == 0:
            os.chmod(tmp, 0o644)
            os.replace(tmp, os.path.join(SHARED, "wallpaper.jpg"))

    face = os.path.join(home, ".face")
    if os.path.isfile(face):
        shutil.copyfile(face, os.path.join(SHARED, "face"))
        os.chmod(os.path.join(SHARED, "face"), 0o644)


def _current_wallpaper(home):
    try:
        with open(os.path.join(home, ".cache", "quickshell", "current_wallpaper")) as f:
            name = f.read().strip()
    except OSError:
        return None
    if os.path.isabs(name):
        return name if os.path.isfile(name) else None
    path = os.path.join(home, "Pictures", "Wallpapers", name)
    return path if os.path.isfile(path) else None


def _write(path, text):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.chmod(tmp, 0o644)
    os.replace(tmp, path)
