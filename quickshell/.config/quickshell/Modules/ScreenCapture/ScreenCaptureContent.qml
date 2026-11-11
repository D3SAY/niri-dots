import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget: null
    property var shotModel: {
        let items = [{
            "label": "Весь экран",
            "icon": "monitor",
            "shotMode": "full",
            "actionType": "shot"
        }, {
            "label": "Через 3 с",
            "icon": "clock",
            "shotMode": "full_3s",
            "actionType": "shot"
        }, {
            "label": "Область",
            "icon": "screenshot-area",
            "shotMode": "area",
            "actionType": "shot"
        }, {
            "label": "Текст с экрана",
            "icon": "ocr",
            "shotMode": "ocr",
            "actionType": "shot"
        }];
        if (RecorderService.running) {
            items.push({
                "label": "Остановить запись",
                "icon": "player-stop",
                "shotMode": "stop_record",
                "actionType": "record"
            });
        } else {
            items.push({
                "label": "Запись экрана",
                "icon": "record-icon",
                "shotMode": "record_full",
                "actionType": "record"
            });
        }
        return items;
    }
    property alias initialFocusItem: shotView
    readonly property int buttonWidth: 64
    readonly property int buttonHeight: Constants.size5Xl

    function hideWidget() {
        if (root.widget && typeof root.widget.close === "function")
            root.widget.close();
        else if (root.widget && root.widget.close !== undefined)
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
        AppState.activeWidget = "";
    }

    function runShot(mode) {
        let scriptPath = Quickshell.shellDir + "/Modules/ScreenCapture/scripts/screenshot.sh";
        Quickshell.execDetached(["bash", scriptPath, mode]);
        root.hideWidget();
    }

    function resetScreenCapture() {
        shotView.currentIndex = 0;
        shotView.forceActiveFocus();
    }

    implicitWidth: buttonWidth * root.shotModel.length
    implicitHeight: buttonHeight
    width: implicitWidth
    height: implicitHeight
    Keys.forwardTo: [shotView]
    Keys.onEscapePressed: {
        root.hideWidget();
    }
    Component.onCompleted: {
        resetScreenCapture();
    }

    Connections {
        function onRunningChanged() {
            if (RecorderService.running)
                root.hideWidget();

        }

        target: RecorderService
    }

    ActionMenu {
        id: shotView

        anchors.fill: parent
        actionModel: root.shotModel
        onActionTriggered: (index) => {
            let item = root.shotModel[index];
            if (item.actionType === "shot") {
                root.runShot(item.shotMode);
            } else if (item.actionType === "record") {
                if (item.shotMode === "record_full")
                    RecorderService.toggle(["-s"]);
                else
                    RecorderService.toggle();
                root.hideWidget();
            }
        }
    }

}
