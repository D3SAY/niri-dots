import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

// VPN in the bar: lit while an AmneziaWG config is up. Left click turns it off, or back on with
// the last used config; right click opens the config list on the right to pick another.
Rectangle {
    id: root

    property bool isHovered: mouseArea.containsMouse
    property bool isPressed: mouseArea.pressed
    readonly property bool isActive: VpnService.connected
    readonly property bool isOpen: AppState.isWidgetOpen("vpn")

    implicitHeight: SettingsService.barWidgetHeight
    implicitWidth: height
    width: implicitWidth
    height: implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.alignment: Qt.AlignVCenter
    color: isActive || isOpen ? Theme.bgAccent : (isHovered ? Theme.bgSecondary : "transparent")
    radius: DisplayProfileService.gameModeActive ? 0 : height / 2
    scale: DisplayProfileService.gameModeActive ? 1 : (isPressed ? 0.92 : (isHovered ? 1.05 : 1))

    SvgIcon {
        anchors.centerIn: parent
        icon: "shield"
        iconColor: root.isActive ? Theme.accent : Theme.muted
        iconSize: Constants.sizeLg
        flat: true
        opacity: VpnService.busy ? 0.5 : 1

        Behavior on iconColor {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    MouseArea {
        id: mouseArea

        z: 10
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                VpnService.refresh();
                AppState.toggleWidget("vpn");
            } else {
                VpnService.quickToggle();
            }
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animFast
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutCubic
        }

    }

}
