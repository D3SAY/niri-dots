import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Card {
    id: root

    readonly property string wallPath: {
        let p = WallpaperManager.currentWallpaperPath;
        if (p && !p.startsWith("/"))
            p = Quickshell.env("HOME") + "/Pictures/Wallpapers/" + p;
        else if (!p && WallpaperManager.currentWallpaper)
            p = WallpaperManager.currentWallpaper.startsWith("/") ? WallpaperManager.currentWallpaper : (Quickshell.env("HOME") + "/Pictures/Wallpapers/" + WallpaperManager.currentWallpaper);
        return p || "";
    }
    readonly property real screenWidth: (root.Screen && root.Screen.width > 0) ? root.Screen.width : ((Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0].width : (Screen.width > 0 ? Screen.width : 1920))
    readonly property real screenHeight: (root.Screen && root.Screen.height > 0) ? root.Screen.height : ((Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0].height : (Screen.height > 0 ? Screen.height : 1080))
    readonly property real screenRatio: screenWidth / Math.max(1, screenHeight)
    readonly property real wallRatio: (wallImage.implicitWidth > 0 && wallImage.implicitHeight > 0) ? (wallImage.implicitWidth / wallImage.implicitHeight) : screenRatio
    readonly property bool isWider: root.wallRatio > (root.screenRatio + 0.005)
    readonly property bool isTaller: root.wallRatio < (root.screenRatio - 0.005)
    readonly property bool isCropMode: NiriSettingsService.wpResizeMode === "crop"

    function getScreenRatioString() {
        let r = root.screenRatio;
        if (Math.abs(r - 16 / 9) < 0.04)
            return "16:9";

        if (Math.abs(r - 16 / 10) < 0.04)
            return "16:10";

        if (Math.abs(r - 21 / 9) < 0.06)
            return "21:9";

        if (Math.abs(r - 32 / 9) < 0.08)
            return "32:9";

        if (Math.abs(r - 4 / 3) < 0.04)
            return "4:3";

        if (Math.abs(r - 9 / 16) < 0.04)
            return "9:16";

        return r.toFixed(2) + ":1";
    }

    function getWallpaperRatioString() {
        let r = root.wallRatio;
        if (Math.abs(r - 16 / 9) < 0.04)
            return "16:9";

        if (Math.abs(r - 16 / 10) < 0.04)
            return "16:10";

        if (Math.abs(r - 21 / 9) < 0.08)
            return "21:9, сверхширокий";

        if (Math.abs(r - 32 / 9) < 0.1)
            return "32:9, сверхширокий";

        if (r > 2)
            return r.toFixed(2) + ":1, сверхширокий";

        if (r < 0.8)
            return r.toFixed(2) + ":1, вертикальный";

        return r.toFixed(2) + ":1";
    }

    function selectPosition(pos) {
        if (!root.isCropMode)
            return ;

        let cur = NiriSettingsService.wpCropGravity;
        if (root.isWider) {
            if (pos === "left")
                NiriSettingsService.wpCropGravity = cur.includes("top") ? "top-left" : (cur.includes("bottom") ? "bottom-left" : "left");
            else if (pos === "right")
                NiriSettingsService.wpCropGravity = cur.includes("top") ? "top-right" : (cur.includes("bottom") ? "bottom-right" : "right");
            else
                NiriSettingsService.wpCropGravity = cur.includes("top") ? "top" : (cur.includes("bottom") ? "bottom" : "center");
        } else if (root.isTaller) {
            if (pos === "top")
                NiriSettingsService.wpCropGravity = cur.includes("left") ? "top-left" : (cur.includes("right") ? "top-right" : "top");
            else if (pos === "bottom")
                NiriSettingsService.wpCropGravity = cur.includes("left") ? "bottom-left" : (cur.includes("right") ? "bottom-right" : "bottom");
            else
                NiriSettingsService.wpCropGravity = cur.includes("left") ? "left" : (cur.includes("right") ? "right" : "center");
        }
    }

    Layout.fillWidth: true
    contentPadding: Constants.sizeLg
    backgroundColor: Theme.bg
    opacity: 0.7
    cardRadius: Constants.sizeSm
    useBorder: true
    borderColor: Theme.border

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeMd

        // Header info
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            SvgIcon {
                icon: "monitor"
                iconSize: 18
                iconColor: Theme.accent
                flat: true
            }

            ColumnLayout {
                spacing: Constants.size3Xs
                Layout.fillWidth: true

                ThemedText {
                    text: "Как обои лягут на экран"
                    font.bold: true
                    customSize: Constants.sizeSm
                    color: Theme.fg
                }

                ThemedText {
                    text: {
                        if (!root.isCropMode)
                            return "Обои целиком (режим" + NiriSettingsService.wpResizeMode + ")";

                        if (root.isWider)
                            return "Широкая картинка на экране" + root.getScreenRatioString() + ". Перетащите или кликните, чтобы выбрать видимую часть.";

                        if (root.isTaller)
                            return "Вертикальная картинка на экране" + root.getScreenRatioString() + ". Перетащите или кликните, чтобы выбрать видимую часть.";

                        return "Обои точно совпадают с разрешением экрана (" + root.getScreenRatioString() + ").";
                    }
                    customSize: Constants.sizeXs + 2
                    color: Theme.muted
                    elide: Text.ElideRight
                }

            }

            // Monitor Resolution Badge
            Rectangle {
                implicitHeight: Constants.size2Xl
                implicitWidth: badgeText.implicitWidth + Constants.sizeMd
                radius: Constants.sizeSm
                color: Theme.bgAccent
                border.width: 1
                border.color: Theme.accent

                ThemedText {
                    id: badgeText

                    anchors.centerIn: parent
                    text: Math.round(root.screenWidth) + " × " + Math.round(root.screenHeight) + " (" + root.getScreenRatioString() + ")"
                    customSize: Constants.sizeXs
                    font.bold: true
                    color: Theme.accent
                }

            }

        }

        // Wallpaper Full Canvas Container with Crop Selection Framing Box
        Item {
            id: previewContainer

            Layout.fillWidth: true
            Layout.preferredHeight: wallCanvas.height + 16

            Rectangle {
                id: wallCanvas

                // Size canvas to show the complete wallpaper uncropped
                readonly property real maxW: Math.min(previewContainer.width - 24, 480)
                readonly property real maxH: 240

                anchors.centerIn: parent
                width: {
                    let w = maxW;
                    let h = w / Math.max(0.1, root.wallRatio);
                    if (h > maxH)
                        return Math.round(maxH * root.wallRatio);

                    return Math.round(w);
                }
                height: Math.round(width / Math.max(0.1, root.wallRatio))
                radius: Constants.sizeXs
                color: Theme.black
                clip: true
                border.width: 1
                border.color: Theme.border

                // Full Wallpaper Image (uncropped)
                Image {
                    id: wallImage

                    anchors.fill: parent
                    source: root.wallPath ? ("file://" + root.wallPath) : ""
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    fillMode: Image.Stretch
                }

                WallpaperCropFrame {
                    id: cropFrameItem

                    previewRoot: root
                    wallCanvas: wallCanvas
                }

                // Interactive Click & Drag Area over the full canvas
                MouseArea {
                    id: clickArea

                    property real startMouseX: 0
                    property real startMouseY: 0

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.isCropMode && (root.isWider || root.isTaller)
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => {
                        startMouseX = mouse.x;
                        startMouseY = mouse.y;
                    }
                    onReleased: (mouse) => {
                        if (root.isWider) {
                            let diffX = mouse.x - startMouseX;
                            if (Math.abs(diffX) > 25) {
                                if (diffX < 0)
                                    root.selectPosition("left");
                                else
                                    root.selectPosition("right");
                            } else {
                                if (mouse.x < wallCanvas.width * 0.35)
                                    root.selectPosition("left");
                                else if (mouse.x > wallCanvas.width * 0.65)
                                    root.selectPosition("right");
                                else
                                    root.selectPosition("center");
                            }
                        } else if (root.isTaller) {
                            let diffY = mouse.y - startMouseY;
                            if (Math.abs(diffY) > 25) {
                                if (diffY < 0)
                                    root.selectPosition("top");
                                else
                                    root.selectPosition("bottom");
                            } else {
                                if (mouse.y < wallCanvas.height * 0.35)
                                    root.selectPosition("top");
                                else if (mouse.y > wallCanvas.height * 0.65)
                                    root.selectPosition("bottom");
                                else
                                    root.selectPosition("center");
                            }
                        }
                    }
                }

            }

        }

        WallpaperCropPositionBar {
            id: cropPositionBar

            previewRoot: root
        }

    }

}
