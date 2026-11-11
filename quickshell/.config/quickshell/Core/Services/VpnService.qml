import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

// AmneziaWG configs in ~/.config/awg through ~/.config/niri/scripts/vpn.sh: which ones exist,
// which one is up, and switching between them (the script asks for the password via polkit).
Item {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/niri/scripts/vpn.sh"
    readonly property string configDir: Quickshell.env("HOME") + "/.config/awg"
    // [{ name, active }]
    property var configs: []
    readonly property string activeName: {
        for (const c of configs) {
            if (c.active)
                return c.name;

        }
        return "";
    }
    readonly property bool connected: activeName !== ""
    // the config being switched to ("" while disconnecting), set while the script runs
    property string pending: ""
    property bool busy: false

    function refresh() {
        if (!listProc.running)
            listProc.running = true;

    }

    function connect(name) {
        if (busy)
            return ;

        pending = name;
        busy = true;
        switchProc.command = [script, "up", name];
        switchProc.running = true;
    }

    function disconnect() {
        if (busy)
            return ;

        pending = "";
        busy = true;
        switchProc.command = [script, "down"];
        switchProc.running = true;
    }

    // the bar button: off if connected, else back on with the last used config (the script picks it)
    function quickToggle() {
        if (busy)
            return ;

        pending = connected ? "" : "…";
        busy = true;
        switchProc.command = [script, "toggle"];
        switchProc.running = true;
    }

    // clicking the connected config turns it off, any other switches to it
    function toggle(name) {
        if (name === activeName)
            disconnect();
        else
            connect(name);
    }

    function openFolder() {
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && xdg-open \"$1\"", "sh", configDir]);
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: listProc

        command: [root.script, "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.configs = text.split("\n").filter((l) => {
                    return l.trim() !== "";
                }).map((l) => {
                    const [name, active] = l.trim().split(" ");
                    return {
                        "name": name,
                        "active": active === "1"
                    };
                });
            }
        }

    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: switchProc

        onExited: {
            root.busy = false;
            root.refresh();
        }
    }

}
