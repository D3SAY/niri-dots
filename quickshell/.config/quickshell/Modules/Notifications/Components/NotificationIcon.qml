import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components

Item {
    id: root

    property var notifData
    property int iconSize: Constants.size3Xl
    property color iconColor: Theme.accent
    property color bgColor: Theme.bgSecondary
    // a themed icon name that the icon theme doesn't have would draw Qt's purple "missing" squares,
    // so names are looked up first and the urgency icon is shown instead when there's no match
    readonly property string iconSource: {
        if (!notifData)
            return "";

        if (notifData.image)
            return notifData.image;

        let icon = notifData.appIcon || "";
        if (icon === "")
            return "";

        if (icon.startsWith("file://") || icon.startsWith("image://"))
            return icon;

        if (icon.startsWith("/"))
            return "file://" + icon;

        return Quickshell.iconPath(icon, true) || "";
    }
    // a source that failed to load (a deleted screenshot, an expired app image) is remembered and
    // not loaded again: switching to the urgency icon resizes this item, and reloading the image at
    // the new size would fail again and loop, freezing the bar
    property string failedSource: ""
    property bool hasAppIcon: iconSource !== "" && iconSource !== failedSource
    property bool isUrgencyIcon: !hasAppIcon

    function getUrgencyIcon() {
        if (!notifData)
            return "info-filled";

        if (notifData.urgency === 2)
            return "warning";

        if (notifData.urgency === 0)
            return "info";

        return "info-filled";
    }

    SvgIcon {
        anchors.fill: parent
        visible: !root.hasAppIcon
        icon: root.hasAppIcon ? "" : getUrgencyIcon()
        iconSize: root.isUrgencyIcon ? Constants.sizeLg : Constants.size2Xl
        iconColor: root.iconColor
        flat: root.isUrgencyIcon
        bgColor: root.isUrgencyIcon ? "transparent" : root.bgColor
        isCircle: false
    }

    Rectangle {
        id: imageBg

        anchors.fill: parent
        visible: root.hasAppIcon
        color: "transparent"
        radius: Constants.sizeXs

        Image {
            id: appImage

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            horizontalAlignment: Image.AlignLeft
            source: root.hasAppIcon ? root.iconSource : ""
            onStatusChanged: {
                if (status === Image.Error)
                    root.failedSource = root.iconSource;

            }
            sourceSize: Qt.size(root.width > 0 ? root.width : root.iconSize, root.height > 0 ? root.height : root.iconSize)
            layer.enabled: true

            layer.effect: OpacityMask {

                maskSource: Rectangle {
                    width: root.width > 0 ? root.width : root.iconSize
                    height: root.height > 0 ? root.height : root.iconSize
                    radius: Constants.sizeXs
                }

            }

        }

    }

}
