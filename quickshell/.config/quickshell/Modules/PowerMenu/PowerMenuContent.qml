import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget: null
    property var menuModel: [{
        "id": "lock",
        "label": "Блокировка",
        "icon": "lock",
        "command": ["sh", "-c", "sleep 0.3; qs ipc call lockScreen lock"],
        "confirm": false
    }, {
        "id": "suspend",
        "label": "Сон",
        "icon": "moon",
        "command": ["sh", "-c", "playerctl -a pause; qs ipc call lockScreen lock; sleep 1; systemctl suspend"],
        "confirm": true
    }, {
        "id": "logout",
        "label": "Выход",
        "icon": "logout",
        "command": ["niri", "msg", "action", "quit", "--skip-confirmation"],
        "confirm": true
    }, {
        "id": "reboot",
        "label": "Перезагрузка",
        "icon": "reload",
        "command": ["systemctl", "reboot"],
        "confirm": true
    }, {
        "id": "shutdown",
        "label": "Выключение",
        "icon": "power",
        "command": ["systemctl", "poweroff"],
        "confirm": true
    }]
    property int pendingActionIndex: -1
    property alias initialFocusItem: menuView
    readonly property int buttonWidth: 64
    readonly property int buttonHeight: Constants.size5Xl

    function closeWidget() {
        if (root.widget && typeof root.widget.close === "function")
            root.widget.close();
        else if (root.widget && root.widget.close !== undefined)
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
        AppState.activeWidget = "";
        root.pendingActionIndex = -1;
    }

    function runAction(index) {
        if (index >= 0 && index < root.menuModel.length) {
            let modelData = root.menuModel[index];
            if (modelData.confirm) {
                root.pendingActionIndex = index;
            } else {
                actionProc.command = modelData.command;
                actionProc.startDetached();
                root.closeWidget();
            }
        }
    }

    function resetPowerMenu() {
        root.pendingActionIndex = -1;
        menuView.currentIndex = 0;
        menuView.forceActiveFocus();
    }

    implicitWidth: buttonWidth * root.menuModel.length
    implicitHeight: buttonHeight
    width: implicitWidth
    height: implicitHeight
    Component.onCompleted: {
        resetPowerMenu();
    }
    onPendingActionIndexChanged: {
        if (pendingActionIndex === -1) {
            menuView.forceActiveFocus();
        } else {
            confirmMenu.currentIndex = 0;
            confirmMenu.forceActiveFocus();
        }
    }

    Process {
        id: actionProc
    }

    ActionMenu {
        id: menuView

        anchors.fill: parent
        visible: opacity > 0
        opacity: root.pendingActionIndex === -1 ? 1 : 0
        scale: root.pendingActionIndex === -1 ? 1 : 0.95
        enabled: root.pendingActionIndex === -1
        actionModel: root.menuModel
        onActionTriggered: (index) => {
            root.runAction(index);
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutBack
            }

        }

    }

    RowLayout {
        id: confirmView

        anchors.fill: parent
        visible: opacity > 0
        opacity: root.pendingActionIndex !== -1 ? 1 : 0
        scale: root.pendingActionIndex !== -1 ? 1 : 0.95
        enabled: root.pendingActionIndex !== -1
        spacing: 0

        Item {
            Layout.preferredWidth: Constants.sizeLg
        }

        ThemedText {
            text: (root.pendingActionIndex !== -1 ? root.menuModel[root.pendingActionIndex].label : "") + "?"
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
        }

        ActionMenu {
            id: confirmMenu

            actionModel: [{
                "label": "Отмена",
                "icon": "x"
            }, {
                "label": "Подтвердить",
                "icon": "check"
            }]
            onActionTriggered: (index) => {
                if (index === 1) {
                    let modelData = root.menuModel[root.pendingActionIndex];
                    actionProc.command = modelData.command;
                    actionProc.startDetached();
                    root.closeWidget();
                } else {
                    root.pendingActionIndex = -1;
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutBack
            }

        }

    }

}
