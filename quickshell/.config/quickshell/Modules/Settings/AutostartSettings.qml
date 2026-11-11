import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

AppContainer {
    id: root

    property var entries: []
    property var apps: []
    property string status: ""

    function run(args) {
        if (backend.running)
            return;
        status = "";
        backend.command = ["python3", Quickshell.shellDir + "/Modules/Settings/scripts/autostart.py"].concat(args);
        backend.running = true;
    }

    Component.onCompleted: run(["list"])

    Process {
        id: backend

        stdout: StdioCollector { id: output }
        stderr: StdioCollector { id: errors }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.status = errors.text.trim() || "Не удалось обновить автозапуск";
                return;
            }
            try {
                const data = JSON.parse(output.text);
                root.entries = data.entries;
                root.apps = data.apps;
                picker.currentIndex = 0;
            } catch (error) {
                root.status = "Не удалось прочитать список автозапуска";
            }
        }
    }

    AppGroup {
        title: "Добавить приложение"
        icon: "plus"

        ThemedSelect {
            id: picker

            label: "Установленные приложения"
            searchable: true
            comboWidth: 260
            model: ["Выберите приложение…"].concat(root.apps.map(app => app.name))
            enabled: !backend.running && root.apps.length > 0
            onActivated: index => {
                if (index > 0)
                    root.run(["add", root.apps[index - 1].desktopFile]);
            }
        }
    }

    ThemedText {
        Layout.fillWidth: true
        text: root.status
        color: Theme.accent
        wrapMode: Text.Wrap
        visible: text !== ""
    }

    AppGroup {
        title: "При входе в сессию"
        icon: "rocket"

        ThemedText {
            text: "Нет приложений в автозапуске"
            color: Theme.muted
            visible: root.entries.length === 0 && !backend.running && root.status === ""
        }

        Repeater {
            model: root.entries

            SettingRowTemplate {
                required property var modelData

                label: modelData.name
                description: modelData.enabled ? "Включено" : "Отключено"

                SvgIconButton {
                    icon: modelData.enabled ? "minus" : "plus"
                    textIcon: modelData.enabled ? "" : "Вернуть"
                    useCustomWidth: !modelData.enabled
                    disabled: backend.running
                    onClicked: root.run([modelData.enabled ? "disable" : "enable", modelData.id])
                }
            }
        }
    }
}
