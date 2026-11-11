import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

// zapret2 (Discord, YouTube and SoundCloud without VPN). Toggling goes through
// ~/.config/niri/scripts/zapret-toggle.sh, which asks for the password via polkit.
QuickSettingsTile {
    id: root

    property bool isVisible: true
    property bool busy: false

    isActive: false
    icon: "rocket"
    label: "Zapret"
    subtitle: busy ? "…" : (isActive ? "Discord, YouTube" : "Выкл")
    onMenuClicked: clicked()
    onClicked: {
        if (root.busy)
            return ;

        root.busy = true;
        toggleProcess.running = true;
    }

    Timer {
        interval: 5000
        running: root.isVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProcess.running = true
    }

    Process {
        id: statusProcess

        command: ["systemctl", "is-active", "--quiet", "zapret2"]
        onExited: (code) => {
            root.isActive = (code === 0);
        }
    }

    Process {
        id: toggleProcess

        command: [Quickshell.env("HOME") + "/.config/niri/scripts/zapret-toggle.sh"]
        onExited: {
            root.busy = false;
            statusProcess.running = true;
        }
    }

}
