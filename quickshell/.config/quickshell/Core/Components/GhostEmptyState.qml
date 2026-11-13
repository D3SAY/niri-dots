import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

ColumnLayout {
    id: root

    property string text: "Здесь пусто…"
    property string icon: "ghost"
    property color iconColor: Theme.muted

    spacing: Constants.sizeMd

    SvgIcon {
        icon: root.icon
        iconColor: root.iconColor
        iconSize: 72
        flat: true
        Layout.alignment: Qt.AlignHCenter
    }

    ThemedText {
        text: root.text
        color: Theme.muted
        customSize: Constants.sizeMd
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
