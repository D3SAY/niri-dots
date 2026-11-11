import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

ListView {
    id: root

    property var actionModel: []
    // each button shows its number; pressing it selects the button, pressing it again runs it
    property bool numbered: true

    signal actionTriggered(int index)

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: 64 * actionModel.length
    Layout.preferredHeight: Constants.size5Xl
    currentIndex: 0
    width: 64 * actionModel.length
    height: Constants.size5Xl
    orientation: ListView.Horizontal
    spacing: 0
    model: actionModel
    clip: true
    focus: true
    keyNavigationEnabled: false
    highlightFollowsCurrentItem: true
    highlightMoveDuration: Constants.animNormal
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Right) {
            if (currentIndex + 1 < actionModel.length) {
                currentIndex++;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Left) {
            if (currentIndex - 1 >= 0) {
                currentIndex--;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.actionTriggered(currentIndex);
            event.accepted = true;
        } else if (root.numbered && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            let target = event.key - Qt.Key_1;
            if (target < actionModel.length) {
                if (currentIndex === target)
                    root.actionTriggered(target);
                else
                    currentIndex = target;
                event.accepted = true;
            }
        }
    }

    QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
        policy: QQC2.ScrollBar.AlwaysOff
        active: true
    }

    highlight: Item {
        width: 64
        height: Constants.size5Xl

        Rectangle {
            anchors.fill: parent
            anchors.margins: Constants.size3Xs
            radius: Constants.sizeSm
            color: Theme.accent
        }

    }

    delegate: Item {
        id: delegateRoot

        readonly property bool isCurrent: root.currentIndex === index

        width: 64
        height: Constants.size5Xl

        Rectangle {
            anchors.fill: parent
            anchors.margins: Constants.size3Xs
            radius: Constants.sizeSm
            color: hoverHandler.hovered && !delegateRoot.isCurrent ? Theme.bgSecondary : "transparent"
        }

        SvgIcon {
            icon: modelData.icon
            iconColor: delegateRoot.isCurrent ? Theme.bg : (hoverHandler.hovered ? Theme.fg : Theme.muted)
            iconSize: Constants.sizeLg
            flat: true
            anchors.centerIn: parent

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ThemedText {
            visible: root.numbered && index < 9
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Constants.size2Xs + 1
            anchors.rightMargin: Constants.sizeXs - 1
            text: index + 1
            customSize: Constants.sizeXs + 1
            font.bold: true
            color: delegateRoot.isCurrent ? Theme.bg : Theme.muted
            opacity: delegateRoot.isCurrent ? 0.8 : 0.7
        }

        ThemedTooltip {
            text: modelData.label
            visible: hoverHandler.hovered
        }

        HoverHandler {
            id: hoverHandler

            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered)
                    root.currentIndex = index;

            }
        }

        TapHandler {
            id: tapHandler

            onTapped: {
                root.currentIndex = index;
                root.actionTriggered(index);
            }
        }

    }

}
