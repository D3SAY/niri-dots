import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

QuickSettingsTile {
    id: root

    isActive: DisplayProfileService.caffeineActive
    icon: !isActive ? "coffee" : "coffee-filled"
    label: "Не спать"
    subtitle: isActive ? "Экран не гаснет" : "Выкл"
    onMenuClicked: clicked()
    onClicked: {
        DisplayProfileService.caffeineActive = !DisplayProfileService.caffeineActive;
    }
}
