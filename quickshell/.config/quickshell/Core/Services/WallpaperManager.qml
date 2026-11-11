import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Services
pragma Singleton

QtObject {
    id: root

    property string currentWallpaper: ""
    property string currentWallpaperPath: ""
    property string pendingWallpaperSave: ""
    property string transitionType: NiriSettingsService.wpTransitionType
    property int transitionStep: NiriSettingsService.wpTransitionStep
    property string transitionPos: NiriSettingsService.wpTransitionPos
    property int transitionFps: NiriSettingsService.wpTransitionFps
    property int transitionAngle: NiriSettingsService.wpTransitionAngle
    property string resizeMode: NiriSettingsService.wpResizeMode
    property string cropGravity: NiriSettingsService.wpCropGravity
    property bool enableTransitions: NiriSettingsService.wpEnableTransitions
    property bool autoShuffle: NiriSettingsService.wpAutoShuffle
    property int shuffleInterval: NiriSettingsService.wpShuffleInterval
    property Process wallpaperApplyProc
    property Process wallpaperSaveProc
    property Process wallpaperLoader
    property Process randomWallpaperProc
    property Process shuffleCheckProc
    property Timer shuffleTimer

    function applyWallpaperWithSync(wallpaperName, rawPath) {
        currentWallpaper = wallpaperName;
        currentWallpaperPath = rawPath;
        saveCurrentWallpaper(wallpaperName);
        applyWallpaper(rawPath);
    }

    function reapplyCurrentWallpaper() {
        let p = currentWallpaperPath;
        if (p && !p.startsWith("/"))
            p = Quickshell.env("HOME") + "/Pictures/Wallpapers/" + p;
        else if (!p && currentWallpaper)
            p = currentWallpaper.startsWith("/") ? currentWallpaper : (Quickshell.env("HOME") + "/Pictures/Wallpapers/" + currentWallpaper);
        if (p)
            applyWallpaperInstant(p);

    }

    function applyWallpaperInstant(rawPath) {
        wallpaperApplyProc.running = false;
        let rMode = NiriSettingsService.wpResizeMode || "crop";
        let gravity = NiriSettingsService.wpCropGravity || "center";
        let cmd = ["awww", "img", rawPath, "--resize", rMode];
        if (rMode === "crop")
            cmd.push("--crop-gravity", gravity);

        cmd.push("--transition-type", "none");
        wallpaperApplyProc.command = cmd;
        wallpaperApplyProc.startDetached();
    }

    function applyWallpaper(rawPath) {
        wallpaperApplyProc.running = false;
        let rMode = NiriSettingsService.wpResizeMode || "crop";
        let gravity = NiriSettingsService.wpCropGravity || "center";
        let cmd = ["awww", "img", rawPath, "--resize", rMode];
        if (rMode === "crop")
            cmd.push("--crop-gravity", gravity);

        if (enableTransitions && SystemInfoService.powerProfile !== "power-saver") {
            cmd.push("--transition-type", transitionType, "--transition-pos", transitionPos, "--transition-step", String(transitionStep), "--transition-fps", String(transitionFps));
            if (transitionType === "wipe" || transitionType === "wave")
                cmd.push("--transition-angle", String(transitionAngle));

            wallpaperApplyProc.command = cmd;
        } else {
            cmd.push("--transition-type", "none");
            wallpaperApplyProc.command = cmd;
        }
        wallpaperApplyProc.startDetached();
    }

    function saveCurrentWallpaper(wallName) {
        if (wallpaperSaveProc.running) {
            pendingWallpaperSave = wallName;
            return;
        }
        wallpaperSaveProc.command = ["sh", "-c",
            "mkdir -p \"$HOME/.cache/quickshell\" && printf '%s\\n' \"$1\" > \"$HOME/.cache/quickshell/current_wallpaper\" && python3 \"$2\"",
            "save-wallpaper", wallName, Quickshell.shellDir + "/Scripts/theme/apply_theme.py"];
        wallpaperSaveProc.running = true;
    }

    function shuffle() {
        randomWallpaperProc.running = false;
        randomWallpaperProc.running = true;
    }

    Component.onCompleted: {
        wallpaperLoader.running = true;
    }

    // The interval counts from the last wallpaper change (the current_wallpaper file's mtime),
    // not from the shell's start, so restarts and reboots don't keep postponing the shuffle.
    shuffleTimer: Timer {
        interval: 60000
        running: root.autoShuffle
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.shuffleCheckProc.running = false;
            root.shuffleCheckProc.running = true;
        }
    }

    shuffleCheckProc: Process {
        command: ["sh", "-c", "f=~/.cache/quickshell/current_wallpaper; [ -f \"$f\" ] && echo $(( $(date +%s) - $(stat -c %Y \"$f\") )) || echo 999999999"]
        onExited: function(exitCode) {
            let age = parseInt(shuffleCheckOutput.text.trim());
            if (exitCode === 0 && !isNaN(age) && age >= root.shuffleInterval * 60)
                root.shuffle();

        }

        stdout: StdioCollector {
            id: shuffleCheckOutput
        }

    }

    wallpaperApplyProc: Process {
    }

    wallpaperSaveProc: Process {
        onExited: function(exitCode) {
            if (exitCode !== 0)
                console.warn("Не удалось сохранить обои или применить тему:", exitCode);
            if (root.pendingWallpaperSave !== "") {
                const name = root.pendingWallpaperSave;
                root.pendingWallpaperSave = "";
                Qt.callLater(root.saveCurrentWallpaper, name);
            }
        }
    }

    randomWallpaperProc: Process {
        // anything but the wallpaper that's already up, unless it's the only one
        command: ["bash", "-c", "cur=$(cat ~/.cache/quickshell/current_wallpaper 2>/dev/null); all=$(find ~/Pictures/Wallpapers -maxdepth 2 -type f 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp|gif)$'); { [ -n \"$cur\" ] && grep -vF -- \"/$cur\" <<< \"$all\" || echo \"$all\"; } | grep . | shuf -n 1 || echo \"$all\" | head -n 1"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                let path = randomWallOutput.text.trim();
                if (path) {
                    let parts = path.split('/');
                    let wallName = parts[parts.length - 1];
                    root.applyWallpaperWithSync(wallName, path);
                }
            }
        }

        stdout: StdioCollector {
            id: randomWallOutput
        }

    }

    wallpaperLoader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/current_wallpaper"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                let name = wallpaperLoaderOutput.text.trim();
                if (name) {
                    root.currentWallpaper = name;
                    root.currentWallpaperPath = name.startsWith("/") ? name : (Quickshell.env("HOME") + "/Pictures/Wallpapers/" + name);
                }
            }
        }

        stdout: StdioCollector {
            id: wallpaperLoaderOutput
        }

    }

}
