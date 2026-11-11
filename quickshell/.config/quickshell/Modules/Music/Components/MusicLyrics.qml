import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: root

    readonly property var lyrics: MprisService.lyrics
    readonly property var lines: lyrics.lines
    readonly property bool synced: lyrics.synced
    readonly property int activeLine: lyrics.activeLine

    function followLine(animate = true) {
        const line = lyricRows.itemAt(activeLine);
        lineHighlight.animateMovement = animate && lineHighlight.row !== null && line !== null;
        lineHighlight.row = line;
        if (lyricsList.dragging || lyricsList.flicking)
            return;
        const maxY = Math.max(0, lyricsList.contentHeight - lyricsList.height);
        const centeredY = line ? line.y + (line.height - lyricsList.height) / 2 : 0;
        const targetY = Math.max(0, Math.min(maxY, centeredY));
        scrollFollow.stop();
        if (animate && Constants.animFast > 0) {
            scrollAnimation.to = targetY;
            if (Math.abs(targetY - lyricsList.contentY) > 0.5)
                scrollFollow.start();
        } else {
            lyricsList.contentY = targetY;
        }
    }

    onLinesChanged: {
        lineHighlight.animateMovement = false;
        lineHighlight.row = null;
        scrollFollow.stop();
        lyricsList.contentY = 0;
        Qt.callLater(followLine, false);
    }
    onActiveLineChanged: Qt.callLater(followLine)
    Component.onCompleted: {
        lyrics.viewers++;
        Qt.callLater(followLine, false);
    }
    Component.onDestruction: lyrics.viewers--

    implicitHeight: 248
    radius: Constants.sizeLg
    color: Theme.bgSecondary
    border.color: Theme.border

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Constants.sizeMd
        spacing: Constants.sizeXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            SvgIcon {
                icon: "quote"
                iconSize: 14
                iconColor: Theme.accent
                flat: true
            }
            ThemedText {
                Layout.fillWidth: true
                text: "Текст песни"
                customSize: 12
                font.weight: Font.DemiBold
            }
            ThemedText {
                text: "Lyse"
                customSize: 10
                color: Theme.muted
            }
        }

        Divider {
            Layout.fillWidth: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ThemedText {
                anchors.centerIn: parent
                width: parent.width - 16
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: root.lines.length === 0
                color: Theme.muted
                text: root.lyrics.errorMessage || (root.lyrics.loading ? "Ищем текст песни…" : root.lyrics.loadedKey ? "Текст для этой песни не найден" : "Включи песню, чтобы увидеть текст")
            }

            Flickable {
                id: lyricsList

                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: lyricColumn.height
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                onMovementStarted: scrollFollow.stop()
                ScrollIndicator.vertical: ScrollIndicator {}

                SequentialAnimation {
                    id: scrollFollow
                    // Let the highlight move visibly before recentering the viewport.
                    PauseAnimation { duration: Math.round(Constants.animFast / 2) }
                    NumberAnimation {
                        id: scrollAnimation
                        target: lyricsList
                        property: "contentY"
                        duration: Constants.animFast
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: lineHighlight

                    property Item row: null
                    property bool animateMovement: false

                    visible: row !== null
                    width: lyricColumn.width
                    y: row ? row.y : 0
                    height: row ? row.height : 0
                    radius: Constants.sizeSm
                    color: Theme.bgAccent

                    Behavior on y {
                        enabled: lineHighlight.animateMovement
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on height {
                        enabled: lineHighlight.animateMovement
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Column {
                    id: lyricColumn
                    width: lyricsList.width - 5

                    Repeater {
                        id: lyricRows
                        model: root.lines

                        delegate: Item {
                            required property int index
                            required property var modelData
                            readonly property bool highlighted: index === root.activeLine
                            width: lyricColumn.width
                            height: lineText.implicitHeight + 14

                            ThemedText {
                                id: lineText
                                anchors.fill: parent
                                anchors.margins: 7
                                text: parent.modelData[1]
                                textFormat: Text.PlainText
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                customSize: 13
                                font.weight: parent.highlighted ? Font.DemiBold : Font.Normal
                                color: parent.highlighted ? Theme.accent : (root.synced ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.64) : Theme.fg)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Constants.animFast
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
