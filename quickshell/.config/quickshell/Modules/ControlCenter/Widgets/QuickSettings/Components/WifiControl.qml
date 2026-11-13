import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell
import qs.Core
import qs.Core.Components

QuickSettingsTile {
    id: root

    property bool expanded: false
    property bool isScanning: wifiScanProc.running
    property var wifiList: []
    property string connectedSsid: "Не подключено"
    property string currentSsid: {
        if (!isActive)
            return "Wi-Fi выключен";

        return connectedSsid;
    }
    property bool isVisible: true

    function toggle() {
        wifiSetProc.command = ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "toggle-radio"];
        wifiSetProc.running = true;

    }

    function scan(forceRescan) {
        if (!root.isActive)
            return ;

        let rescan = (forceRescan === undefined) ? true : forceRescan;
        wifiScanProc.command = ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "scan", rescan ? "yes" : "no"];
        wifiScanProc.running = false;
        wifiScanProc.running = true;
    }

    function connect(ssid) {
        wifiConnectProc.command = ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "connect", ssid];
        wifiConnectProc.running = true;
    }

    readonly property var ethernetDevices: speed.connection.ethernet || []
    property string ethernetError: ""

    NetworkSpeed {
        id: speed
        monitoring: root.isVisible
    }

    hasContextMenu: true
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.description: subtitle + ". Shift+F10 — действия сети"
    Accessible.onPressAction: root.menuClicked()
    border.width: activeFocus ? 1 : 0
    border.color: Theme.accent
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers === Qt.ShiftModifier)) {
            root.contextRequested();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.menuClicked();
        } else {
            return;
        }
        event.accepted = true;
    }
    onContextRequested: {
        if (networkMenu.opened)
            networkMenu.close();
        else
            networkMenu.open();
    }

    hasMenu: true
    menuWhileInactive: true
    icon: root.isActive ? "wifi" : "wifi-off"
    label: speed.running ? speed.stage : speed.resultCurrent ? "Сеть · " + speed.latency : "Сеть"
    subtitle: speed.running ? "Проверка скорости…" : ethernetError || speed.error
        || speed.summary || speed.connection.name || root.currentSsid
    onClicked: root.menuClicked()

    Popup {
        id: networkMenu

        x: 0
        y: root.height + 4
        width: Math.max(root.width, 210)
        height: (actions.implicitHeight + 2 * padding) * reveal
        padding: Constants.sizeXs
        clip: true
        opacity: reveal
        property real reveal: 0
        property bool restoreFocus: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onAboutToShow: restoreFocus = root.activeFocus
        onOpened: wifiAction.forceActiveFocus()
        onClosed: {
            if (restoreFocus && root.isVisible)
                root.forceActiveFocus();
        }

        enter: Transition {
            NumberAnimation {
                target: networkMenu
                property: "reveal"
                to: 1
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                target: networkMenu
                property: "reveal"
                to: 0
                duration: Constants.animFast
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            color: Theme.bg
            radius: Constants.sizeSm + networkMenu.padding
            border.color: Theme.border
        }

        contentItem: Item {
            ColumnLayout {
                id: actions
                width: parent.width
                spacing: Constants.size2Xs

                NetworkAction {
                    id: wifiAction
                    Layout.fillWidth: true
                    actionIcon: root.isActive ? "wifi-off" : "wifi"
                    text: root.isActive ? "Выключить Wi-Fi" : "Включить Wi-Fi"
                    enabled: !wifiSetProc.running
                    onClicked: {
                        networkMenu.close();
                        root.toggle();
                    }
                }

                Repeater {
                    model: root.ethernetDevices
                    NetworkAction {
                        required property var modelData
                        Layout.fillWidth: true
                        actionIcon: "monitor"
                        text: (modelData.active ? "Отключить Ethernet" : "Подключить Ethernet")
                            + (root.ethernetDevices.length > 1 ? " · " + modelData.device : "")
                        enabled: !ethernetProc.running
                        onClicked: {
                            networkMenu.close();
                            root.ethernetError = "";
                            ethernetProc.command = ["nmcli", "--wait", "12", "device",
                                modelData.active ? "disconnect" : "connect", modelData.device];
                            ethernetProc.running = true;
                        }
                    }
                }

                NetworkAction {
                    Layout.fillWidth: true
                    actionIcon: speed.running ? "x" : "refresh"
                    text: speed.running ? "Отменить замер" : "Проверить скорость"
                    onClicked: {
                        networkMenu.close();
                        root.ethernetError = "";
                        speed.toggleTest();
                    }
                }
            }
        }

    }

    Process {
        id: ethernetProc
        onExited: code => {
            if (code !== 0)
                root.ethernetError = "Ошибка Ethernet";
            speed.refreshConnection();
        }
    }
    onIsVisibleChanged: {
        if (!isVisible)
            networkMenu.close();
        if (isVisible && isActive && root.wifiList.length === 0)
            scan(false);
    }
    onExpandedChanged: {
        if (expanded)
            scan(true);

    }
    onIsActiveChanged: {
        if (isActive) {
            scan(false);
            if (expanded)
                scan(true);

        } else {
            wifiList = [];
            connectedSsid = "Не подключено";
        }
    }
    Component.onCompleted: {
        if (isActive && root.wifiList.length === 0)
            scan(false);

    }

    Timer {
        interval: 2000
        running: root.isVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiGetProc.running = true;
        }
    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: wifiGetProc

        command: ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "status"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let st = JSON.parse(data.trim());
                    root.isActive = st.radio;
                    root.connectedSsid = st.connected_ssid || "Не подключено";
                } catch (e) {
                }
            }
        }

    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: wifiSetProc

        onRunningChanged: {
            if (!running)
                wifiGetProc.running = true;

        }
    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: wifiScanProc

        command: ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "scan"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let list = JSON.parse(data.trim());
                    if (Array.isArray(list))
                        root.wifiList = list;

                } catch (e) {
                }
            }
        }

    }

    Process {
        // command output is parsed: keep it in English with dot decimals
        environment: ({"LC_ALL": "C.UTF-8"})

        id: wifiConnectProc

        onRunningChanged: {
            if (!running) {
                wifiGetProc.running = true;
                root.scan(true);
            }
        }
    }

}
