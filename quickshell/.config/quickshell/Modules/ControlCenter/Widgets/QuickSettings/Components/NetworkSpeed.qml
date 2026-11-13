import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool monitoring: false
    property var connection: ({})
    property var result: null
    property string stage: ""
    property string error: ""
    property bool cancelled: false
    property bool receivedResult: false
    readonly property string script: Quickshell.shellDir + "/Modules/ControlCenter/scripts/network_speed.py"

    readonly property bool running: test.running
    readonly property bool resultCurrent: !!result && result.connection.key === connection.key
    readonly property string summary: resultCurrent
        ? "↓ " + metric(result.download, 1) + "  ↑ " + metric(result.upload, 1) + " Мбит/с" : ""
    readonly property string latency: resultCurrent ? metric(result.latency, 0) + " мс" : ""

    function refreshConnection() {
        probe.running = true;
    }

    function toggleTest() {
        if (test.running) {
            cancelled = true;
            stage = "Отмена…";
            test.running = false;
            return;
        }
        cancelled = false;
        receivedResult = false;
        error = "";
        stage = "Подключение…";
        test.running = true;
    }

    function metric(value, decimals) {
        return Number(value).toLocaleString(Qt.locale("ru_RU"), "f", decimals);
    }

    Process {
        id: probe
        command: ["python3", root.script, "connection"]
        stdout: StdioCollector {
            id: probeOutput
        }
        onExited: code => {
            if (code === 0)
                root.connection = JSON.parse(probeOutput.text);
        }
    }

    Timer {
        interval: 2500
        running: root.monitoring
        triggeredOnStart: true
        repeat: true
        onTriggered: root.refreshConnection()
    }

    Process {
        id: test
        command: ["python3", root.script]
        stdout: SplitParser {
            onRead: line => {
                if (root.cancelled)
                    return;
                const data = JSON.parse(line);
                if (data.stage) {
                    const stages = {latency: "Задержка…", download: "Загрузка…", upload: "Отдача…"};
                    root.stage = stages[data.stage];
                } else if (data.error) {
                    root.error = data.error;
                    root.receivedResult = true;
                } else {
                    root.result = data;
                    root.receivedResult = true;
                }
            }
        }
        onExited: {
            root.stage = "";
            if (!root.cancelled && !root.receivedResult)
                root.error = "Не удалось выполнить замер.";
        }
    }

}
