import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: settingsService

    property bool settingsLoaded: false
    property string packageManagerMode: "install"
    property int clipboardMaxItems: 100
    property var enabledKbLayouts: ["us", "latam"]
    property string musicPlayer: "none"
    property string musicPlayerCommand: ""
    property bool isSettingsLoading: settingsLoader.running
    property string quoteCategory: "All"
    property string fontFamily: "Geist"
    property real fontScale: 1
    property bool clock24h: true
    property bool clockSeconds: false
    property bool clockShowDate: true
    property string cursorTheme: "Bibata-Modern-Classic"
    property int cursorSize: Constants.size2Xl
    property string barStyle: "convex"
    property bool barIslandMode: barStyle === "island"
    property bool barConvexMode: barStyle === "convex"
    property string islandRightMode: "auto"
    readonly property int barWidgetHeight: 28
    property int numberOfWorkspaces: 10

    function saveSettings() {
        saveTimer.restart();
    }

    function load() {
        if (!settingsLoaded && !isSettingsLoading)
            settingsLoader.running = true;

    }

    function applyCursor(theme, size) {
        let t = theme !== undefined ? theme : cursorTheme;
        let s = size !== undefined ? size : cursorSize;
        applyCursorProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/apply_cursor.py", t, s.toString()];
        applyCursorProc.running = false;
        applyCursorProc.running = true;
    }

    function applyFont(font, size) {
        let f = font !== undefined ? font : fontFamily;
        let s = size !== undefined ? size : Math.round(11 * fontScale);
        applyFontProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/apply_font.py", f, s.toString()];
        applyFontProc.running = false;
        applyFontProc.running = true;
    }

    Component.onCompleted: {
        load();
    }
    onClipboardMaxItemsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onEnabledKbLayoutsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onMusicPlayerChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onMusicPlayerCommandChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onQuoteCategoryChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onFontFamilyChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyFont(fontFamily, Math.round(11 * fontScale));
        }
    }
    onFontScaleChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyFont(fontFamily, Math.round(11 * fontScale));
        }
    }
    onClock24hChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onClockSecondsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onClockShowDateChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onCursorThemeChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyCursor(cursorTheme, cursorSize);
        }
    }
    onCursorSizeChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyCursor(cursorTheme, cursorSize);
        }
    }
    onBarStyleChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onIslandRightModeChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onNumberOfWorkspacesChanged: {
        if (settingsLoaded)
            saveSettings();

    }

    Timer {
        id: saveTimer

        interval: 100
        repeat: false
        onTriggered: {
            let data = {
                "performanceInterval": SystemInfoService.performanceInterval,
                "powerProfile": SystemInfoService.powerProfile,
                "packageManagerChecksEnabled": UpdateService.packageManagerChecksEnabled,
                "packageManagerCheckInterval": UpdateService.packageManagerCheckInterval,
                "clipboardMaxItems": settingsService.clipboardMaxItems,
                "enabledKbLayouts": settingsService.enabledKbLayouts,
                "animationSpeedFactor": NiriSettingsService.animationSpeedFactor,
                "musicPlayer": settingsService.musicPlayer,
                "musicPlayerCommand": settingsService.musicPlayerCommand,
                "nightLightActive": DisplayProfileService.nightLightActive,
                "caffeineActive": DisplayProfileService.caffeineActive,
                "gameModeActive": DisplayProfileService.gameModeActive,
                "nightLightTemperature": DisplayProfileService.nightLightTemperature,
                "keyboardLayout": NiriSettingsService.keyboardLayout,
                "wpAutoShuffle": NiriSettingsService.wpAutoShuffle,
                "wpShuffleInterval": NiriSettingsService.wpShuffleInterval,
                "wpEnableTransitions": NiriSettingsService.wpEnableTransitions,
                "wpTransitionType": NiriSettingsService.wpTransitionType,
                "wpTransitionPos": NiriSettingsService.wpTransitionPos,
                "wpTransitionStep": NiriSettingsService.wpTransitionStep,
                "wpTransitionFps": NiriSettingsService.wpTransitionFps,
                "wpTransitionAngle": NiriSettingsService.wpTransitionAngle,
                "wpResizeMode": NiriSettingsService.wpResizeMode,
                "wpCropGravity": NiriSettingsService.wpCropGravity,
                "micMuted": AudioService.micMuted,
                "micVolume": AudioService.micVolume,
                "quoteCategory": settingsService.quoteCategory,
                "fontFamily": settingsService.fontFamily,
                "fontScale": settingsService.fontScale,
                "clock24h": settingsService.clock24h,
                "clockSeconds": settingsService.clockSeconds,
                "clockShowDate": settingsService.clockShowDate,
                "cursorTheme": settingsService.cursorTheme,
                "cursorSize": settingsService.cursorSize,
                "barStyle": settingsService.barStyle,
                "islandRightMode": settingsService.islandRightMode,
                "numberOfWorkspaces": settingsService.numberOfWorkspaces
            };
            settingsSaver.running = false;
            settingsSaver.command = ["sh", "-c",
                "umask 077; dir=\"$HOME/.cache/quickshell\"; mkdir -p \"$dir\" && printf '%s\\n' \"$1\" > \"$dir/settings_prefs.json.tmp\" && mv -f \"$dir/settings_prefs.json.tmp\" \"$dir/settings_prefs.json\"",
                "save-settings", JSON.stringify(data)];
            settingsSaver.running = true;
        }
    }

    Process {
        id: settingsLoader

        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/settings_prefs.json"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                let raw = settingsOutput.text ? settingsOutput.text.trim() : "";
                if (raw.length > 0) {
                    try {
                        let prefs = JSON.parse(raw);
                        if (prefs.powerProfile !== undefined) {
                            SystemInfoService.powerProfile = prefs.powerProfile;
                            SystemInfoService.applyProfile(prefs.powerProfile);
                        } else {
                            SystemInfoService.applyProfile("balanced");
                        }
                        if (prefs.performanceInterval !== undefined)
                            SystemInfoService.performanceInterval = prefs.performanceInterval;

                        if (prefs.packageManagerChecksEnabled !== undefined)
                            UpdateService.packageManagerChecksEnabled = prefs.packageManagerChecksEnabled;

                        if (prefs.packageManagerCheckInterval !== undefined)
                            UpdateService.packageManagerCheckInterval = prefs.packageManagerCheckInterval;

                        if (prefs.clipboardMaxItems !== undefined)
                            settingsService.clipboardMaxItems = prefs.clipboardMaxItems;

                        if (prefs.animationSpeedFactor !== undefined)
                            NiriSettingsService.animationSpeedFactor = prefs.animationSpeedFactor;

                        if (prefs.musicPlayer !== undefined)
                            settingsService.musicPlayer = prefs.musicPlayer;

                        if (prefs.musicPlayerCommand !== undefined)
                            settingsService.musicPlayerCommand = prefs.musicPlayerCommand;

                        if (prefs.nightLightActive !== undefined)
                            DisplayProfileService.nightLightActive = prefs.nightLightActive;

                        if (prefs.caffeineActive !== undefined)
                            DisplayProfileService.caffeineActive = prefs.caffeineActive;

                        if (prefs.gameModeActive !== undefined)
                            DisplayProfileService.gameModeActive = prefs.gameModeActive;

                        if (prefs.nightLightTemperature !== undefined)
                            DisplayProfileService.nightLightTemperature = prefs.nightLightTemperature;

                        if (prefs.keyboardLayout !== undefined)
                            NiriSettingsService.keyboardLayout = prefs.keyboardLayout;

                        if (prefs.enabledKbLayouts !== undefined)
                            settingsService.enabledKbLayouts = prefs.enabledKbLayouts;

                        if (prefs.wpAutoShuffle !== undefined)
                            NiriSettingsService.wpAutoShuffle = prefs.wpAutoShuffle;

                        if (prefs.wpShuffleInterval !== undefined)
                            NiriSettingsService.wpShuffleInterval = prefs.wpShuffleInterval;

                        if (prefs.wpEnableTransitions !== undefined)
                            NiriSettingsService.wpEnableTransitions = prefs.wpEnableTransitions;

                        if (prefs.wpTransitionType !== undefined)
                            NiriSettingsService.wpTransitionType = prefs.wpTransitionType;

                        if (prefs.wpTransitionPos !== undefined)
                            NiriSettingsService.wpTransitionPos = prefs.wpTransitionPos;

                        if (prefs.wpTransitionStep !== undefined)
                            NiriSettingsService.wpTransitionStep = prefs.wpTransitionStep;

                        if (prefs.wpTransitionFps !== undefined)
                            NiriSettingsService.wpTransitionFps = prefs.wpTransitionFps;

                        if (prefs.wpTransitionAngle !== undefined)
                            NiriSettingsService.wpTransitionAngle = prefs.wpTransitionAngle;

                        if (prefs.wpResizeMode !== undefined)
                            NiriSettingsService.wpResizeMode = prefs.wpResizeMode;

                        if (prefs.wpCropGravity !== undefined)
                            NiriSettingsService.wpCropGravity = prefs.wpCropGravity;

                        if (prefs.micVolume !== undefined && AudioService.hasPhysicalMic)
                            AudioService.setMicVolume(prefs.micVolume);

                        if (prefs.micMuted !== undefined && AudioService.hasPhysicalMic)
                            AudioService.setMicMuted(prefs.micMuted);

                        if (prefs.quoteCategory !== undefined)
                            settingsService.quoteCategory = prefs.quoteCategory;

                        if (prefs.fontFamily !== undefined)
                            settingsService.fontFamily = prefs.fontFamily;

                        if (prefs.fontScale !== undefined)
                            settingsService.fontScale = prefs.fontScale;

                        if (prefs.clock24h !== undefined)
                            settingsService.clock24h = prefs.clock24h;

                        if (prefs.clockSeconds !== undefined)
                            settingsService.clockSeconds = prefs.clockSeconds;

                        if (prefs.clockShowDate !== undefined)
                            settingsService.clockShowDate = prefs.clockShowDate;

                        if (prefs.cursorTheme !== undefined)
                            settingsService.cursorTheme = prefs.cursorTheme;

                        if (prefs.cursorSize !== undefined)
                            settingsService.cursorSize = prefs.cursorSize;

                        applyCursor(settingsService.cursorTheme, settingsService.cursorSize);
                        applyFont(settingsService.fontFamily, Math.round(11 * settingsService.fontScale));
                        if (prefs.barStyle !== undefined) {
                            if (prefs.barStyle === "island")
                                settingsService.barStyle = "island";
                            else
                                settingsService.barStyle = "convex";
                        }
                        if (prefs.islandRightMode !== undefined)
                            settingsService.islandRightMode = prefs.islandRightMode;

                        if (prefs.numberOfWorkspaces !== undefined)
                            settingsService.numberOfWorkspaces = prefs.numberOfWorkspaces;

                    } catch (e) {
                        console.error("Error loading settings: " + e);
                        SystemInfoService.applyProfile("balanced");
                    }
                } else {
                    SystemInfoService.applyProfile("balanced");
                    settingsService.saveSettings();
                }
            } else {
                SystemInfoService.applyProfile("balanced");
                settingsService.saveSettings();
                settingsService.applyCursor(settingsService.cursorTheme, settingsService.cursorSize);
                settingsService.applyFont(settingsService.fontFamily, Math.round(11 * settingsService.fontScale));
            }
            settingsService.settingsLoaded = true;
        }

        stdout: StdioCollector {
            id: settingsOutput
        }

    }

    Process {
        id: settingsSaver
    }

    Process {
        id: applyCursorProc
    }

    Process {
        id: applyFontProc
    }

}
