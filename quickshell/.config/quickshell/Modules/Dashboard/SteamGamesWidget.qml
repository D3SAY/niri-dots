import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Installed Steam games as cover cards; a click starts the game and closes the dashboard
Card {
    id: root

    readonly property int columns: 2
    readonly property real coverWidth: (width - contentPadding * 2 - grid.columnSpacing * (columns - 1)) / columns
    // as tall as its games, up to two rows of covers; more scroll
    readonly property real maxGridHeight: coverWidth * 1.5 * 2 + grid.rowSpacing
    readonly property real bodyHeight: SteamService.games.length > 0 ? Math.min(grid.implicitHeight, maxGridHeight) : emptyState.implicitHeight

    function countText(n) {
        let tens = n % 100, ones = n % 10;
        let word = (tens >= 11 && tens <= 14) ? "игр" : (ones === 1 ? "игра" : (ones >= 2 && ones <= 4 ? "игры" : "игр"));
        return n + " " + word;
    }

    clip: true
    contentPadding: Constants.sizeLg
    implicitWidth: 280
    implicitHeight: header.implicitHeight + Constants.sizeSm + bodyHeight + contentPadding * 2
    onVisibleChanged: {
        if (visible)
            SteamService.refresh();

    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeSm

        RowLayout {
            id: header

            Layout.fillWidth: true
            spacing: Constants.sizeXs

            SvgIcon {
                icon: "gamepad"
                iconSize: Constants.sizeLg
                iconColor: Theme.fg
                flat: true
            }

            ThemedText {
                text: "Steam"
                font.bold: true
                color: Theme.fg
                customSize: Constants.sizeMd
            }

            Item {
                Layout.fillWidth: true
            }

            ThemedText {
                text: SteamService.games.length > 0 ? root.countText(SteamService.games.length) : ""
                color: Theme.muted
                customSize: Constants.sizeXs + 2
            }

        }

        Flickable {
            id: flick

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: grid.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            visible: SteamService.games.length > 0

            GridLayout {
                id: grid

                width: flick.width
                columns: root.columns
                columnSpacing: Constants.sizeSm
                rowSpacing: Constants.sizeSm

                Repeater {
                    model: SteamService.games

                    delegate: Item {
                        id: tile

                        required property var modelData

                        Layout.preferredWidth: root.coverWidth
                        Layout.preferredHeight: root.coverWidth * 1.5
                        scale: tileHover.hovered ? 1.03 : 1

                        Rectangle {
                            id: frame

                            anchors.fill: parent
                            radius: Constants.sizeSm
                            color: Theme.bgSecondary
                            border.width: tileHover.hovered ? 2 : 0
                            border.color: Theme.accent
                            // round the cover's corners too
                            layer.enabled: true

                            layer.effect: OpacityMask {

                                maskSource: Rectangle {
                                    width: frame.width
                                    height: frame.height
                                    radius: frame.radius
                                }

                            }

                            // no cover yet: the name on a plain card
                            ThemedText {
                                anchors.fill: parent
                                anchors.margins: Constants.sizeSm
                                visible: cover.status !== Image.Ready
                                text: tile.modelData.name
                                color: Theme.fg
                                font.bold: true
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Image {
                                id: cover

                                anchors.fill: parent
                                anchors.margins: frame.border.width
                                source: tile.modelData.art ? "file://" + tile.modelData.art : ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 240
                                asynchronous: true
                                smooth: true
                                visible: status === Image.Ready
                            }

                            // name strip on hover
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: nameText.implicitHeight + Constants.sizeSm * 2
                                visible: cover.status === Image.Ready
                                opacity: tileHover.hovered ? 1 : 0
                                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.85)

                                ThemedText {
                                    id: nameText

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Constants.sizeSm
                                    text: tile.modelData.name
                                    color: Theme.fg
                                    font.bold: true
                                    customSize: Constants.sizeXs + 2
                                    elide: Text.ElideRight
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Constants.animFast
                                    }

                                }

                            }

                        }

                        HoverHandler {
                            id: tileHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
                                SteamService.launch(tile.modelData.id);
                                AppState.closeAllWidgets();
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Constants.animFast
                                easing.type: Easing.OutQuad
                            }

                        }

                    }

                }

            }

        }

        // nothing installed (or Steam not set up)
        ColumnLayout {
            id: emptyState

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: SteamService.loaded && SteamService.games.length === 0
            spacing: Constants.sizeSm

            Item {
                Layout.fillHeight: true
            }

            SvgIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "gamepad"
                iconSize: Constants.size4Xl
                flat: true
                iconColor: Theme.accent
            }

            ThemedText {
                text: "Нет установленных игр"
                color: Theme.fg
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            ThemedText {
                text: "Установите игру в Steam, и она появится здесь."
                color: Theme.muted
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Item {
                Layout.fillHeight: true
            }

        }

    }

}
