import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Core.Services

RectangularShadow {
    id: root

    property bool active: true

    visible: active && NiriSettingsService.shadowEnabled && !DisplayProfileService.gameModeActive && (SystemInfoService.powerProfile !== "power-saver")
    blur: NiriSettingsService.shadowRange
    spread: NiriSettingsService.shadowSoftness
    color: Theme.shadow
}
