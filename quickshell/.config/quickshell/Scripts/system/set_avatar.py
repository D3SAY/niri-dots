#!/usr/bin/env python3
import io
import os
import sys
import tempfile
from pathlib import Path
from urllib.parse import unquote_to_bytes, urlsplit

from PIL import Image, ImageOps


def atomic_write(destination, data, mode):
    with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as file:
        temporary = Path(file.name)
        try:
            file.write(data)
            file.close()
            temporary.chmod(mode)
            temporary.replace(destination)
        finally:
            temporary.unlink(missing_ok=True)


def avatar_png(source):
    with Image.open(source) as image:
        image = ImageOps.exif_transpose(image).convert("RGBA")
        avatar = ImageOps.fit(image, (256, 256), Image.Resampling.LANCZOS)
    output = io.BytesIO()
    avatar.save(output, "PNG")
    return output.getvalue()


def main():
    source = urlsplit(sys.argv[1])
    if source.scheme != "file" or source.netloc not in ("", "localhost"):
        raise ValueError("Нужно выбрать локальный файл")
    png = avatar_png(Path(os.fsdecode(unquote_to_bytes(source.path))))
    atomic_write(Path.home() / ".face", png, 0o600)
    greeter = Path("/var/cache/minflair-greeter")
    if os.access(greeter, os.W_OK):
        try:
            atomic_write(greeter / "face", png, 0o644)
        except OSError:
            print("Аватар сохранён. Экран входа обновится при следующем применении темы.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, Image.DecompressionBombError):
        sys.exit("Не удалось сохранить аватар. Проверь, что файл открывается как изображение.")
