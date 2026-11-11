import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Widgets.SystemTray as STray

Rectangle {
    id: root

    property bool forceHide: false
    property bool compact: false
    property bool hasBackground: true
    property int customHeight: compact ? 22 : SettingsService.barWidgetHeight
    readonly property real sideMargin: compact ? 6 : (hasBackground ? Constants.sizeXs : 0)
    readonly property real itemSpacing: compact ? 4 : (hasBackground ? Constants.sizeSm : Constants.size3Xs)
    readonly property int visibleItemCount: {
        const model = trayItems.model;
        const items = model && typeof model.values !== "function" ? model.values : model;
        return Array.from(items || []).filter(item => !SettingsService.isTrayItemHidden(item)).length;
    }
    readonly property real itemsWidth: visibleItemCount * customHeight + Math.max(0, visibleItemCount - 1) * itemSpacing
    readonly property bool shouldShow: !forceHide && visibleItemCount > 0
    readonly property real targetWidth: Math.min(itemsWidth + sideMargin * 2, Layout.maximumWidth)

    implicitHeight: customHeight
    implicitWidth: shouldShow ? targetWidth : 0
    width: implicitWidth
    height: implicitHeight
    Layout.preferredHeight: customHeight
    Layout.alignment: Qt.AlignVCenter
    Layout.maximumWidth: 240 + sideMargin * 2
    Layout.preferredWidth: implicitWidth
    opacity: shouldShow ? 1 : 0
    visible: opacity > 0.001 && implicitWidth > 0.5
    clip: true
    color: hasBackground ? Theme.bgSecondary : "transparent"
    radius: DisplayProfileService.gameModeActive ? 0 : height / 2

    Flickable {
        id: trayFlick

        anchors.fill: parent
        anchors.leftMargin: root.sideMargin
        anchors.rightMargin: root.sideMargin
        contentWidth: root.itemsWidth
        contentHeight: height
        onContentWidthChanged: contentX = Math.max(0, Math.min(contentX, contentWidth - width))
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        interactive: false
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                trayFlick.contentX = Math.max(0, Math.min(trayFlick.contentX - (wheel.angleDelta.y / 2), trayFlick.contentWidth - trayFlick.width));
            }
        }

        RowLayout {
            id: trayRow

            height: parent.height
            spacing: root.itemSpacing

            Repeater {
                id: trayItems

                model: SystemTray.items

                delegate: STray.TrayItem {
                    trayItem: modelData
                    itemIndex: index
                    visible: !SettingsService.isTrayItemHidden(trayItem)
                    customHeight: root.customHeight
                    iconSize: root.compact ? (Constants.sizeSm - 1) : Constants.sizeSm
                    onClicked: (mouse) => {
                        let isRight = (mouse.button === Qt.RightButton);
                        let isMenuClick = isRight || (mouse.button === Qt.LeftButton && modelData.onlyMenu);
                        if (isMenuClick) {
                            AppState.activeTrayItem = modelData;
                            AppState.toggleWidget("systemTray_" + index);
                        } else {
                            if (AppState.activeWidget.startsWith("systemTray_"))
                                AppState.closeWidget(AppState.activeWidget);

                            for (let i = 0; i < AppState.activeWidgetsList.length; i++) {
                                let w = AppState.activeWidgetsList[i];
                                if (w && w.startsWith("systemTray_"))
                                    AppState.closeWidget(w);

                            }
                        }
                    }
                }

            }

        }

    }

    Behavior on Layout.preferredWidth {
        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

}
