#!/usr/bin/env python3
"""Use the installed Lyse backend with explicitly selected media."""

import json
import runpy
import subprocess
import sys
import time


def panel(api, title, artist, album, duration):
    config = api["Config"].load()
    lyse = api["Lyse"](config, None)
    lines, synced = lyse._fetch_lyrics(title, artist, album, float(duration), 0)
    if lines == [(0, "no lyrics :(")]:
        lines = []
    print(json.dumps({"lines": lines or [], "synced": synced, "offset": config.offset}))


def terminal(api):
    original = api["Poller"]

    class PlayingPoller(original):
        def __init__(self, player=None):
            super().__init__(player)
            self.selected = player

        def now_playing(self):
            if self.player:
                return super().now_playing()
            try:
                result = subprocess.run(
                    ["playerctl", "-a", "status", "--format", "{{playerInstance}} {{status}}"],
                    capture_output=True, text=True, timeout=2, check=False,
                )
            except (OSError, subprocess.TimeoutExpired):
                return None
            playing = []
            paused = []
            for line in result.stdout.splitlines():
                instance, _, state = line.rpartition(" ")
                if instance and state == "Playing":
                    playing.append(instance)
                elif instance and state == "Paused":
                    paused.append(instance)
            if playing and self.selected not in playing:
                self.selected = playing[0]
            if self.selected not in playing + paused:
                self.selected = None
                return None
            self._base = ["playerctl", "-p", self.selected]
            track = super().now_playing()
            if track:
                track["track_id"] = self.selected + ":" + (track["track_id"] or track["title"])
            return track

    class TargetedLyse(api["Lyse"]):
        def _handle_key(self, key):
            curses = api["curses"]
            if key in (curses.KEY_RIGHT, curses.KEY_LEFT):
                if self.poller.selected:
                    forward = key == curses.KEY_RIGHT
                    self.poller._cmd(["position", "5+" if forward else "5-"])
                    self._seek_flash = "+5s" if forward else "-5s"
                    self._seek_flash_at = time.monotonic()
                return
            return super()._handle_key(key)

    api["main"].__globals__.update(Poller=PlayingPoller, Lyse=TargetedLyse)
    api["main"]()


if __name__ == "__main__":
    api = runpy.run_path("/usr/bin/lyse")
    if sys.argv[1:2] == ["--panel-lyrics"]:
        panel(api, *sys.argv[2:])
    else:
        terminal(api)
