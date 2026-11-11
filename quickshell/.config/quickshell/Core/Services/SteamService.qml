import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

// Installed Steam games that are ready to launch (scripts/steam_games.py reads the app manifests)
Item {
    id: root

    property var games: []
    property bool loaded: false

    function refresh() {
        if (!listProc.running)
            listProc.running = true;

    }

    function launch(appId) {
        Quickshell.execDetached(["steam", "steam://rungameid/" + appId]);
    }

    Component.onCompleted: refresh()

    Process {
        id: listProc

        command: ["python3", Quickshell.shellDir + "/Core/Services/scripts/steam_games.py"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.games = JSON.parse(text);
                } catch (e) {
                    root.games = [];
                }
                root.loaded = true;
            }
        }

    }

}
