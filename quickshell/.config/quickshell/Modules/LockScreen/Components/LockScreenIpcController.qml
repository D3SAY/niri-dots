import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core.Services

Item {
    id: root

    property bool authenticating: false
    property bool authFailed: false
    property bool unlocking: false
    // set by LockScreen; read by hypridle through "qs ipc call lockScreen isLocked"
    property bool locked: false
    // true once niri confirms the screen is really locked (the autologin check waits for it)
    property bool secure: false

    signal authSucceeded()
    signal toggleLockRequested()

    function reset() {
        root.authFailed = false;
        root.authenticating = false;
        root.unlocking = false;
    }

    function submitPassword(pwd) {
        if (root.authenticating)
            return ;

        authProc.running = false;
        root.authenticating = true;
        root.authFailed = false;
        authProc.command = ["python3", Quickshell.shellDir + "/Scripts/system/auth.py"];
        authProc.running = true;
        authProc.write(pwd + "\n");
    }

    IpcHandler {
        function toggle() {
            root.toggleLockRequested();
        }

        function lock() {
            root.toggleLockRequested();
        }

        function isLocked(): string {
            return root.locked ? "true" : "false";
        }

        function isSecure(): string {
            return root.secure ? "true" : "false";
        }

        target: "lockScreen"
    }

    Process {
        id: authProc

        onExited: function(exitCode) {
            if (!root.authenticating)
                return ;

            root.authenticating = false;
            if (exitCode === 0) {
                root.unlocking = true;
                root.authSucceeded();
            } else {
                root.authFailed = true;
            }
        }
    }

}
