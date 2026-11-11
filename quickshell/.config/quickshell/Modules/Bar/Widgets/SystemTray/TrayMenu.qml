import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services

ColumnLayout {
    id: trayMenuRoot

    property var menuHandle: null
    property var trayItem: null
    property var menuStack: []
    property string title: "Меню"
    property var activeChildren: trayMenuRoot.menuStack.length > 1 ? subOpener.children : rootOpener.children
    property int prevStackLength: 1
    property real contentSlideX: 0
    property real contentOpacity: 1

    signal backRequested()
    signal closeRequested()

    function resetToRoot() {
        if (menuHandle)
            trayMenuRoot.menuStack = [menuHandle];
        else
            trayMenuRoot.menuStack = [];
    }

    function isRedundantSeparator(idx) {
        let children = trayMenuRoot.activeChildren;
        if (!children)
            return false;

        let list = (children && children.values) ? children.values : children;
        if (!list || !list.length)
            return false;

        let prevIsSeparator = true;
        for (let i = idx - 1; i >= 0; i--) {
            let prev = list[i];
            if (prev && (prev.text !== "" || prev.isSeparator)) {
                if (!prev.isSeparator)
                    prevIsSeparator = false;

                break;
            }
        }
        if (prevIsSeparator)
            return true;

        let nextIsSeparator = true;
        for (let i = idx + 1; i < list.length; i++) {
            let next = list[i];
            if (next && (next.text !== "" || next.isSeparator)) {
                if (!next.isSeparator)
                    nextIsSeparator = false;

                break;
            }
        }
        if (nextIsSeparator)
            return true;

        return false;
    }

    Component.onCompleted: {
        resetToRoot();
    }
    spacing: Constants.sizeXs
    onMenuHandleChanged: {
        if (menuHandle)
            trayMenuRoot.menuStack = [menuHandle];
        else
            trayMenuRoot.menuStack = [];
    }
    onMenuStackChanged: {
        let newLen = menuStack.length;
        if (newLen <= 1) {
            contentSlideX = 0;
            contentOpacity = 1;
            prevStackLength = 1;
            if (scrollView && scrollView.contentItem)
                scrollView.contentItem.contentY = 0;

            return ;
        }
        let goingDeeper = newLen > prevStackLength;
        prevStackLength = newLen;
        if (scrollView && scrollView.contentItem)
            scrollView.contentItem.contentY = 0;

        contentSlideX = goingDeeper ? 14 : -14;
        contentOpacity = 0.2;
        slideInAnim.restart();
    }

    ParallelAnimation {
        id: slideInAnim

        NumberAnimation {
            target: trayMenuRoot
            property: "contentSlideX"
            to: 0
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: trayMenuRoot
            property: "contentOpacity"
            to: 1
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

    QsMenuOpener {
        id: rootOpener

        menu: trayMenuRoot.menuHandle
    }

    QsMenuOpener {
        id: subOpener

        menu: trayMenuRoot.menuStack.length > 1 ? trayMenuRoot.menuStack[trayMenuRoot.menuStack.length - 1] : null
    }

    RowLayout {
        id: headerRow

        Layout.fillWidth: true
        spacing: Constants.sizeSm

        SvgIcon {
            id: backIcon

            icon: "chevron-left"
            iconColor: backHover.hovered ? Theme.accent : Theme.muted
            iconSize: Constants.sizeLg
            flat: true
            visible: trayMenuRoot.menuStack.length > 1
            scale: backHover.hovered ? 1.15 : 1

            HoverHandler {
                id: backHover
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let s = trayMenuRoot.menuStack.slice();
                    s.pop();
                    trayMenuRoot.menuStack = s;
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutQuad
                }

            }

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ThemedText {
            text: trayMenuRoot.menuStack.length > 1 ? (trayMenuRoot.menuStack[trayMenuRoot.menuStack.length - 1].text || "Назад") : trayMenuRoot.title
            customSize: Constants.sizeLg
            font.bold: true
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

    }

    Divider {
    }

    SvgIconButton {
        Layout.fillWidth: true
        visible: SettingsService.settingsLoaded && SettingsService.trayItemId(trayMenuRoot.trayItem) !== "" && trayMenuRoot.menuStack.length <= 1
        icon: "eye-off"
        iconSize: Constants.sizeSm
        iconColor: Theme.accent
        textIcon: "Скрыть из трея"
        textIconSize: 12
        contentAlignment: Qt.AlignLeft
        onClicked: mouse => {
            if (mouse.button !== Qt.LeftButton)
                return;
            SettingsService.hideTrayItem(trayMenuRoot.trayItem);
            trayMenuRoot.closeRequested();
        }
    }

    ScrollView {
        id: scrollView

        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitWidth: itemsColumn.implicitWidth
        implicitHeight: itemsColumn.implicitHeight
        clip: true
        contentWidth: availableWidth
        contentHeight: itemsColumn.implicitHeight
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: itemsColumn

            width: parent.width
            spacing: Constants.sizeXs
            opacity: trayMenuRoot.contentOpacity

            Repeater {
                model: trayMenuRoot.activeChildren

                delegate: TrayMenuItemDelegate {
                    menuRoot: trayMenuRoot
                }

            }

            transform: Translate {
                x: trayMenuRoot.contentSlideX
            }

        }

        ScrollBar.vertical: ScrollBar {
            id: vbar

            active: true
            policy: ScrollBar.AsNeeded
            width: Constants.size2Xs

            contentItem: Rectangle {
                implicitWidth: Constants.size2Xs
                radius: width / 2
                color: Theme.accent
                opacity: vbar.active ? 0.6 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animFast
                    }

                }

            }

        }

    }

}
