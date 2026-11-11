import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

QuickSettingsTile {
    id: root

    isActive: DisplayProfileService.nightLightActive
    icon: isActive ? "moon-filled" : "moon"
    label: "Ночной свет"
    subtitle: isActive ? "Вкл" : "Выкл"
    onMenuClicked: clicked()
    onClicked: {
        DisplayProfileService.nightLightActive = !DisplayProfileService.nightLightActive;
    }
}
