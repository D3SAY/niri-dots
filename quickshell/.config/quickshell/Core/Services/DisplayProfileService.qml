import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services
pragma Singleton

Item {
    id: displayProfileService

    property bool nightLightActive: false
    property int nightLightTemperature: 4500
    property bool caffeineActive: false
    property bool gameModeActive: false
    property bool gameModeDaemonDetected: false
    property bool autoActivatedByDaemon: false
    readonly property string gameModeSubtitle: {
        if (!gameModeActive)
            return "Выкл";

        if (gameModeDaemonDetected)
            return "Игра (gamemode)";

        return "Макс. производительность";
    }

    function applyNightLight(state) {
        if (state) {
            // wlsunset with "night" from 00:00 to 23:59 keeps the warm temperature on all day
            nightLightProc.command = ["wlsunset", "-s", "00:00", "-S", "23:59", "-t", displayProfileService.nightLightTemperature.toString(), "-T", "6500"];
            nightLightProc.running = false;
            nightLightProc.running = true;
        } else {
            nightLightProc.running = false;
            pkillSunsetProc.running = false;
            pkillSunsetProc.running = true;
        }
    }

    function applyCaffeine(state) {
        caffeineProc.running = false;
        if (state)
            caffeineProc.running = true;

    }

    function applyGameMode(enable) {
        gameModePwrProc.command = ["python3", Quickshell.shellDir + "/Core/Services/scripts/game_mode.py", enable ? "apply" : "revert"];
        gameModePwrProc.running = false;
        gameModePwrProc.running = true;
        displayProfileService.caffeineActive = enable;
        // niri: game mode turns animations and shadows off through the generated include
        NiriSettingsService.setGameMode(enable);
    }

    Component.onCompleted: {
        if (gameModeActive)
            applyGameMode(true);

    }
    onNightLightActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applyNightLight(nightLightActive);
    }
    onNightLightTemperatureChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        if (nightLightActive)
            applyNightLight(true);

    }
    onCaffeineActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applyCaffeine(caffeineActive);
    }
    onGameModeActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applyGameMode(gameModeActive);
    }

    Timer {
        id: gameDaemonPollTimer

        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkGameDaemonProc.running)
                checkGameDaemonProc.running = true;

        }
    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: checkGameDaemonProc

        command: ["python3", Quickshell.shellDir + "/Core/Services/scripts/game_mode.py", "status"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let info = JSON.parse(data.trim());
                    if (info.gamemode_active) {
                        displayProfileService.gameModeDaemonDetected = true;
                        if (!displayProfileService.gameModeActive) {
                            displayProfileService.autoActivatedByDaemon = true;
                            displayProfileService.gameModeActive = true;
                        }
                    } else {
                        displayProfileService.gameModeDaemonDetected = false;
                        if (displayProfileService.gameModeActive && displayProfileService.autoActivatedByDaemon) {
                            displayProfileService.autoActivatedByDaemon = false;
                            displayProfileService.gameModeActive = false;
                        }
                    }
                } catch (e) {
                }
            }
        }

    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: gameModePwrProc
    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: nightLightProc
    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: pkillSunsetProc

        command: ["pkill", "-x", "wlsunset"]
    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: caffeineProc

        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Keep screen active", "--mode=block", "sleep", "infinity"]
    }

}
