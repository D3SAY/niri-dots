import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Services
pragma Singleton

// niri compositor and shell preferences. Values that affect niri are stored in
// ~/.cache/quickshell/niri_prefs.json and applied through the generated
// ~/.config/niri/minflair.kdl include (Core/Services/scripts/niri_prefs.py).
Item {
    id: niriSettingsService

    property bool enableAnimations: true
    property real animationSpeedFactor: 1
    property string keyboardLayout: "us"
    property bool wpAutoShuffle: false
    property int wpShuffleInterval: 10
    property bool wpEnableTransitions: true
    property string wpTransitionType: "grow"
    property string wpTransitionPos: "center"
    property int wpTransitionStep: 120
    property int wpTransitionFps: 60
    property int wpTransitionAngle: 30
    property string wpResizeMode: "crop"
    property string wpCropGravity: "center"
    property int cornerRadius: 8
    property int activeOpacity: 100
    property int inactiveOpacity: 100
    property int gaps: 10
    property int borderSize: 0
    property bool shadowEnabled: true
    property int shadowRange: 8
    property int shadowSoftness: 3
    property real mouseSensitivity: 0
    property string mouseAccelProfile: "flat"
    property bool mouseNaturalScroll: false
    property real mouseScrollFactor: 1
    property bool mouseLeftHanded: false
    property int mouseFollowMouse: 1
    property int cursorInactiveTimeout: 5
    property bool touchpadNaturalScroll: true
    property bool touchpadTapToClick: true
    property bool touchpadDisableWhileTyping: true
    property bool prefsLoaded: false
    property bool isSyncing: false
    readonly property bool isTrueFullscreen: NiriService.focusedWorkspace ? NiriService.focusedWorkspace.hasFullscreen : false

    // niri reports layout names ("English (US)"); minflair works with xkb codes ("us")
    readonly property var layoutCodes: ({
        "English (US)": "us",
        "English (UK)": "gb",
        "Russian": "ru",
        "Ukrainian": "ua",
        "German": "de",
        "French": "fr",
        "Spanish": "es",
        "Polish": "pl"
    })

    function codeForName(name) {
        if (layoutCodes[name] !== undefined)
            return layoutCodes[name];

        return name.toLowerCase().slice(0, 2);
    }

    function _write(obj) {
        writeProc.command = ["python3", Quickshell.shellDir + "/Core/Services/scripts/niri_prefs.py", "write", JSON.stringify(obj)];
        writeProc.running = false;
        writeProc.running = true;
    }

    function applySettings() {
        if (!prefsLoaded || isSyncing)
            return ;

        applySettingsTimer.restart();
    }

    function applyMouseSettings() {
        applySettings();
    }

    function setPowerSaverMode(enabled) {
        _write({
            "_powerSaver": enabled
        });
    }

    function setGameMode(enabled) {
        _write({
            "_gameMode": enabled
        });
    }

    onKeyboardLayoutChanged: {
        if (isSyncing || !SettingsService.settingsLoaded)
            return ;

        SettingsService.saveSettings();
        const names = NiriService.keyboardLayoutNames;
        for (let i = 0; i < names.length; i++) {
            if (codeForName(names[i]) === keyboardLayout) {
                NiriService.switchLayout(i);
                return ;
            }
        }
    }
    onEnableAnimationsChanged: applySettings()
    onAnimationSpeedFactorChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applySettings();
    }
    onCornerRadiusChanged: applySettings()
    onActiveOpacityChanged: applySettings()
    onInactiveOpacityChanged: applySettings()
    onGapsChanged: applySettings()
    onBorderSizeChanged: applySettings()
    onShadowEnabledChanged: applySettings()
    onShadowRangeChanged: applySettings()
    onMouseSensitivityChanged: applySettings()
    onMouseAccelProfileChanged: applySettings()
    onMouseNaturalScrollChanged: applySettings()
    onMouseScrollFactorChanged: applySettings()
    onMouseLeftHandedChanged: applySettings()
    onMouseFollowMouseChanged: applySettings()
    onCursorInactiveTimeoutChanged: applySettings()
    onTouchpadNaturalScrollChanged: applySettings()
    onTouchpadTapToClickChanged: applySettings()
    onTouchpadDisableWhileTypingChanged: applySettings()
    onWpAutoShuffleChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpShuffleIntervalChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpEnableTransitionsChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionTypeChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionPosChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionStepChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionFpsChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionAngleChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpResizeModeChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            WallpaperManager.reapplyCurrentWallpaper();
        }
    }
    onWpCropGravityChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            WallpaperManager.reapplyCurrentWallpaper();
        }
    }
    Component.onCompleted: readPrefsProc.running = true

    // keep keyboardLayout in sync with niri without re-triggering a switch
    Connections {
        function onKeyboardLayoutNameChanged() {
            const code = niriSettingsService.codeForName(NiriService.keyboardLayoutName);
            if (code && niriSettingsService.keyboardLayout !== code) {
                niriSettingsService.isSyncing = true;
                niriSettingsService.keyboardLayout = code;
                niriSettingsService.isSyncing = false;
            }
        }

        target: NiriService
    }

    Timer {
        id: applySettingsTimer

        interval: 100
        repeat: false
        onTriggered: niriSettingsService._write({
            "animations": niriSettingsService.enableAnimations,
            "animationSpeed": niriSettingsService.animationSpeedFactor,
            "rounding": niriSettingsService.cornerRadius,
            "activeOpacity": niriSettingsService.activeOpacity,
            "inactiveOpacity": niriSettingsService.inactiveOpacity,
            "gaps": niriSettingsService.gaps,
            "borderSize": niriSettingsService.borderSize,
            "shadow": niriSettingsService.shadowEnabled,
            "shadowRange": niriSettingsService.shadowRange,
            "mouseSensitivity": niriSettingsService.mouseSensitivity,
            "mouseAccelProfile": niriSettingsService.mouseAccelProfile,
            "mouseNaturalScroll": niriSettingsService.mouseNaturalScroll,
            "mouseScrollFactor": niriSettingsService.mouseScrollFactor,
            "mouseLeftHanded": niriSettingsService.mouseLeftHanded,
            "focusFollowsMouse": niriSettingsService.mouseFollowMouse !== 0,
            "cursorInactiveTimeout": niriSettingsService.cursorInactiveTimeout,
            "touchpadNaturalScroll": niriSettingsService.touchpadNaturalScroll,
            "touchpadTapToClick": niriSettingsService.touchpadTapToClick,
            "touchpadDisableWhileTyping": niriSettingsService.touchpadDisableWhileTyping
        })
    }

    Process {
        id: writeProc
    }

    Process {
        id: readPrefsProc

        command: ["python3", Quickshell.shellDir + "/Core/Services/scripts/niri_prefs.py", "render"]
        onExited: {
            niriSettingsService.isSyncing = false;
            niriSettingsService.prefsLoaded = true;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const p = JSON.parse(this.text.trim());
                    niriSettingsService.isSyncing = true;
                    niriSettingsService.enableAnimations = p.animations;
                    niriSettingsService.animationSpeedFactor = p.animationSpeed;
                    niriSettingsService.cornerRadius = p.rounding;
                    niriSettingsService.activeOpacity = p.activeOpacity;
                    niriSettingsService.inactiveOpacity = p.inactiveOpacity;
                    niriSettingsService.gaps = p.gaps;
                    niriSettingsService.borderSize = p.borderSize;
                    niriSettingsService.shadowEnabled = p.shadow;
                    niriSettingsService.shadowRange = p.shadowRange;
                    niriSettingsService.mouseSensitivity = p.mouseSensitivity;
                    niriSettingsService.mouseAccelProfile = p.mouseAccelProfile;
                    niriSettingsService.mouseNaturalScroll = p.mouseNaturalScroll;
                    niriSettingsService.mouseScrollFactor = p.mouseScrollFactor;
                    niriSettingsService.mouseLeftHanded = p.mouseLeftHanded;
                    niriSettingsService.mouseFollowMouse = p.focusFollowsMouse ? 1 : 0;
                    niriSettingsService.cursorInactiveTimeout = p.cursorInactiveTimeout;
                    niriSettingsService.touchpadNaturalScroll = p.touchpadNaturalScroll;
                    niriSettingsService.touchpadTapToClick = p.touchpadTapToClick;
                    niriSettingsService.touchpadDisableWhileTyping = p.touchpadDisableWhileTyping;
                } catch (e) {
                    console.error("Error parsing niri prefs: " + e);
                }
            }
        }

    }

}
