import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

GridLayout {
    id: root

    property var widget
    property bool isVertical: false

    columns: isVertical ? 1 : 2
    rows: isVertical ? 2 : 1
    rowSpacing: isVertical ? Constants.sizeLg : Constants.sizeMd
    columnSpacing: Constants.sizeMd
    implicitWidth: isVertical ? 440 : (leftCol.implicitWidth + rightCol.implicitWidth + columnSpacing)
    implicitHeight: isVertical ? (leftCol.implicitHeight + rightCol.implicitHeight + rowSpacing) : Math.max(leftCol.implicitHeight, rightCol.implicitHeight)

    ColumnLayout {
        id: leftCol

        spacing: root.isVertical ? Constants.sizeLg : Constants.sizeMd
        Layout.fillWidth: true
        Layout.preferredWidth: root.isVertical ? -1 : steamWidget.implicitWidth
        Layout.fillHeight: !root.isVertical
        implicitWidth: steamWidget.implicitWidth
        implicitHeight: steamWidget.implicitHeight

        SteamGamesWidget {
            id: steamWidget

            Layout.fillWidth: true
            Layout.fillHeight: !root.isVertical
        }

    }

    ColumnLayout {
        id: rightCol

        readonly property real contentColWidth: updatesCard.implicitWidth

        Layout.alignment: Qt.AlignTop
        spacing: root.isVertical ? Constants.sizeLg : Constants.sizeMd
        Layout.fillWidth: true
        Layout.preferredWidth: root.isVertical ? -1 : contentColWidth
        Layout.fillHeight: !root.isVertical
        implicitWidth: contentColWidth
        implicitHeight: updatesCard.implicitHeight

        UpdatesCard {
            id: updatesCard

            widget: root.widget
            Layout.fillWidth: true
            Layout.fillHeight: false
        }

    }

}
