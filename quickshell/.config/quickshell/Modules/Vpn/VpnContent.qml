import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

// The VPN button's drawer: every config in ~/.config/awg, click one to connect to it (the one
// that's up gets dropped), click the connected one to disconnect.
Item {
    id: root

    signal closeRequested()

    implicitWidth: 320
    implicitHeight: column.implicitHeight + Constants.sizeLg * 2

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        spacing: Constants.sizeSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            ThemedText {
                text: "VPN"
                customSize: Constants.sizeMd
                font.bold: true
            }

            ThemedText {
                Layout.fillWidth: true
                text: VpnService.busy ? "…" : (VpnService.connected ? VpnService.activeName : "Выкл")
                customSize: Constants.sizeSm
                color: VpnService.connected ? Theme.accent : Theme.muted
                elide: Text.ElideRight
            }

            SvgIconButton {
                icon: "folder"
                iconSize: Constants.sizeMd
                iconColor: Theme.muted
                flat: true
                padding: Constants.size2Xs
                onClicked: {
                    VpnService.openFolder();
                    root.closeRequested();
                }
            }

            SvgIconButton {
                icon: "x"
                iconSize: Constants.sizeMd
                iconColor: Theme.muted
                flat: true
                padding: Constants.size2Xs
                onClicked: root.closeRequested()
            }

        }

        Repeater {
            model: VpnService.configs

            delegate: Rectangle {
                id: row

                required property var modelData
                readonly property bool isActive: modelData.active
                readonly property bool isPending: VpnService.busy && VpnService.pending === modelData.name

                Layout.fillWidth: true
                Layout.preferredHeight: Constants.size4Xl
                radius: Constants.sizeSm
                color: isActive ? Theme.bgAccent : (rowArea.containsMouse ? Theme.bgSecondary : Theme.bgTertiary)
                opacity: VpnService.busy && !isPending && !isActive ? 0.5 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Constants.sizeMd
                    anchors.rightMargin: Constants.sizeMd
                    spacing: Constants.sizeSm

                    SvgIcon {
                        icon: "shield"
                        iconSize: Constants.sizeLg
                        iconColor: row.isActive ? Theme.accent : Theme.muted
                        flat: true
                    }

                    ThemedText {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        customSize: Constants.sizeSm
                        font.weight: row.isActive ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }

                    ThemedText {
                        text: row.isPending ? "Подключение…" : (row.isActive ? (VpnService.busy && VpnService.pending === "" ? "Отключение…" : "Подключено") : "")
                        customSize: Constants.sizeXs + 2
                        color: row.isActive ? Theme.accent : Theme.muted
                    }

                }

                MouseArea {
                    id: rowArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: VpnService.busy ? Qt.BusyCursor : Qt.PointingHandCursor
                    onClicked: VpnService.toggle(row.modelData.name)
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

            }

        }

        ThemedText {
            Layout.fillWidth: true
            Layout.topMargin: Constants.size2Xs
            visible: VpnService.configs.length === 0
            text: "Нет конфигов. Положите .conf-файлы AmneziaWG или WireGuard в ~/.config/awg"
            customSize: Constants.sizeSm
            color: Theme.muted
            wrapMode: Text.Wrap
        }

    }

}
