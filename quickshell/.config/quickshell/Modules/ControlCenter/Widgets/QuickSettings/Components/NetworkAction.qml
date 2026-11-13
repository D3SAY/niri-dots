import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

ItemDelegate {
    id: root
    property string actionIcon

    implicitHeight: 34
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    leftPadding: 10
    rightPadding: 10
    contentItem: RowLayout {
        spacing: Constants.sizeXs

        SvgIcon {
            icon: root.actionIcon
            iconColor: root.enabled ? Theme.accent : Theme.muted
            iconSize: 15
            flat: true
        }

        ThemedText {
            Layout.fillWidth: true
            text: root.text
            textFormat: Text.PlainText
            color: root.enabled ? Theme.fg : Theme.muted
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            customSize: 12
        }
    }
    background: Rectangle {
        color: root.hovered || root.down || root.visualFocus ? Theme.bgAccent : "transparent"
        radius: Constants.sizeSm
        border.width: root.visualFocus ? 1 : 0
        border.color: Theme.accent

        Behavior on color {
            ColorAnimation { duration: Constants.animFast }
        }
    }
}
