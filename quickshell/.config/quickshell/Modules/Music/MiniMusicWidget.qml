import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Music.Components

Item {
    id: root

    property var widget: null
    property var cavaData: CavaService.cavaData
    readonly property real artSize: metadataColumn.implicitHeight
    readonly property real playerWidth: 410
    readonly property bool isVisibleOnScreen: widget !== null && widget.isOpen !== undefined ? widget.isOpen : true
    property real lyricsReveal: AppState.musicLyricsExpanded ? 1 : 0

    implicitWidth: playerWidth
    implicitHeight: mainRow.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Behavior on lyricsReveal {
        enabled: root.isVisibleOnScreen && Constants.animSlow > 0
        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }
    }

    ColumnLayout {
        id: mainRow

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        RowLayout {
            id: playerColumn

            Layout.preferredWidth: root.playerWidth
            Layout.fillWidth: false
            Layout.fillHeight: false
            spacing: Constants.sizeLg

            // COVER ART
            Item {
                id: artSection

                Layout.preferredWidth: root.artSize
                Layout.preferredHeight: root.artSize
                Layout.alignment: Qt.AlignHCenter

                Image {
                    id: artImage

                    readonly property string artUrl: MprisService.activePlayer ? (MprisService.activePlayer.trackArtUrl || "") : ""
                    property int retries: 0

                    anchors.fill: parent
                    source: artUrl
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    asynchronous: true
                    visible: false
                    onArtUrlChanged: retries = 0
                    // a cover download that failed once (network blip, VPN switching) is never tried
                    // again for the same URL, so try a few more times
                    onStatusChanged: {
                        if (status === Image.Error && artUrl.startsWith("http") && retries < 5)
                            artRetry.restart();

                    }

                    Timer {
                        id: artRetry

                        interval: 2000 * (artImage.retries + 1)
                        onTriggered: {
                            artImage.retries++;
                            artImage.source = "";
                            artImage.source = Qt.binding(() => {
                                return artImage.artUrl;
                            });
                        }
                    }

                }

                Rectangle {
                    id: artMask

                    anchors.fill: parent
                    radius: Constants.sizeLg
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: artImage
                    maskSource: artMask
                    visible: artImage.status === Image.Ready && MprisService.activePlayer !== null
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Constants.sizeLg
                    color: Theme.bgSecondary
                    visible: artImage.status !== Image.Ready || MprisService.activePlayer === null

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "music"
                        iconSize: parent.width * 0.4
                        iconColor: Theme.accent
                        flat: true
                    }

                }

            }

            // METADATA
            ColumnLayout {
                id: metadataColumn

                Layout.fillWidth: true
                spacing: Constants.size2Xs

                RowLayout {
                    Rectangle {
                        visible: true
                        color: (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none") ? Theme.accent : Theme.bgSecondary
                        radius: Constants.sizeSm
                        Layout.preferredHeight: Constants.size2Xl
                        Layout.preferredWidth: badgeLbl.implicitWidth + 24

                        ThemedText {
                            id: badgeLbl

                            anchors.centerIn: parent
                            text: (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none") ? "Выбрать плеер" : (MprisService.activePlayerName !== "" ? MprisService.activePlayerName : MprisService.getDisplayName(SettingsService.musicPlayer))
                            customSize: Constants.sizeXs + 2
                            font.bold: true
                            color: (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none") ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none")
                            onClicked: {
                                AppState.pendingSettingsTab = 4;
                                AppState.openWidget("minflair_settings");
                            }
                        }

                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    SvgIconButton {
                        icon: "quote"
                        textIcon: "Текст"
                        textIconSize: 11
                        iconSize: 13
                        padding: 5
                        useCustomWidth: true
                        isActive: AppState.musicLyricsExpanded
                        iconColor: isActive ? Theme.bg : Theme.fg
                        onClicked: AppState.musicLyricsExpanded = !AppState.musicLyricsExpanded
                    }

                }

                TypewriterText {
                    text: MprisService.activePlayer ? (MprisService.activePlayer.trackTitle || "Ничего не играет") : "Нет музыки"
                    customSize: Constants.sizeMd
                    font.weight: Font.Bold
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                TypewriterText {
                    text: MprisService.activePlayer ? (MprisService.activePlayer.trackArtist || "Неизвестный исполнитель") : ((!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none") ? "Нажмите ниже, чтобы настроить" : "Откройте музыкальный плеер")
                    customSize: Constants.sizeSm
                    color: Theme.accentComplementary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                MusicProgressBar {
                }

                // CONTROLS
                MusicPlayerControls {
                    currentLoopState: {
                        if (!MprisService.activePlayer || !MprisService.activePlayer.loopSupported)
                            return 0;

                        return MprisService.activePlayer.loopState;
                    }
                    isShuffleActive: {
                        if (!MprisService.activePlayer || !MprisService.activePlayer.shuffleSupported)
                            return false;

                        return MprisService.activePlayer.shuffle;
                    }
                }

                // CAVA VISUALIZER BOTTOM
                MusicCavaBars {
                    cavaData: root.cavaData
                }

            }

        }

        Item {
            id: lyricsViewport

            Layout.fillWidth: true
            Layout.preferredHeight: root.lyricsReveal * (Constants.sizeMd + (lyricsLoader.item ? lyricsLoader.item.implicitHeight : 0))
            visible: root.lyricsReveal > 0
            clip: true

            Loader {
                id: lyricsLoader

                anchors.top: parent.top
                anchors.topMargin: Constants.sizeMd
                anchors.left: parent.left
                anchors.right: parent.right
                active: root.isVisibleOnScreen && (AppState.musicLyricsExpanded || root.lyricsReveal > 0)
                sourceComponent: Component {
                    MusicLyrics {}
                }
            }
        }

    }

}
