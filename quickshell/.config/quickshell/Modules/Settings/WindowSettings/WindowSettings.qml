import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    AppGroup {
        title: "Окна и отступы"
        icon: "window"

        SettingSpinBox {
            label: "Скругление окон"
            from: 0
            to: 40
            stepSize: 1
            value: NiriSettingsService.cornerRadius
            defaultValue: 32
            suffix: "px"
            onMoved: (val) => {
                NiriSettingsService.cornerRadius = Math.round(val);
            }
        }

        SettingSpinBox {
            label: "Отступы от краёв"
            description: "Может сломать раскладку стиля Convex"
            from: 0
            to: 40
            stepSize: 1
            value: NiriSettingsService.gaps
            defaultValue: Constants.sizeXs
            suffix: "px"
            onMoved: (val) => {
                NiriSettingsService.gaps = Math.round(val);
            }
        }

        SettingSpinBox {
            label: "Толщина рамки"
            from: 0
            to: 10
            stepSize: 1
            value: NiriSettingsService.borderSize
            defaultValue: 2
            suffix: "px"
            onMoved: (val) => {
                NiriSettingsService.borderSize = Math.round(val);
            }
        }

    }

}
