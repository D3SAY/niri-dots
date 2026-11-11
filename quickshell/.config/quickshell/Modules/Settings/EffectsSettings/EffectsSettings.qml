import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    AppGroup {
        title: "Анимации"
        icon: "sparkles"

        SettingSpinBox {
            label: "Скорость анимаций"
            description: "Скорость переходов и затуханий интерфейса"
            from: 0
            to: 2
            stepSize: 0.1
            value: NiriSettingsService.enableAnimations ? NiriSettingsService.animationSpeedFactor : 0
            suffix: "x"
            decimals: 1
            allowOff: true
            offText: "Выкл"
            onMoved: (val) => {
                if (val <= 0.001) {
                    NiriSettingsService.enableAnimations = false;
                } else {
                    if (!NiriSettingsService.enableAnimations)
                        NiriSettingsService.enableAnimations = true;

                    NiriSettingsService.animationSpeedFactor = Number(val.toFixed(1));
                }
            }
        }

    }

    AppGroup {
        title: "Эффекты композитора"
        icon: "window"

        SettingSpinBox {
            label: "Непрозрачность"
            description: "Прозрачность окон и оболочки"
            from: 50
            to: 100
            stepSize: 5
            value: NiriSettingsService.activeOpacity
            defaultValue: 100
            suffix: "%"
            onMoved: (val) => {
                let intVal = Math.round(val);
                NiriSettingsService.activeOpacity = intVal;
                NiriSettingsService.inactiveOpacity = intVal;
                NiriSettingsService.applySettings();
                Theme.bgOpacity = intVal / 100;
                Theme.saveScheme();
            }
        }

        SettingToggle {
            id: shadowToggle

            label: "Тени окон и оболочки"
            onCheckedChanged: {
                if (checked !== NiriSettingsService.shadowEnabled)
                    NiriSettingsService.shadowEnabled = checked;

            }

            Binding on checked {
                value: NiriSettingsService.shadowEnabled
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd
            enabled: NiriSettingsService.shadowEnabled
            opacity: enabled ? 1 : 0.5

            SettingSpinBox {
                label: "Размер тени"
                from: 1
                to: 60
                stepSize: 1
                value: NiriSettingsService.shadowRange
                defaultValue: 20
                suffix: "px"
                onMoved: (val) => {
                    NiriSettingsService.shadowRange = Math.round(val);
                }
            }

            SettingSpinBox {
                label: "Мягкость тени"
                from: 1
                to: 4
                stepSize: 1
                value: NiriSettingsService.shadowSoftness
                defaultValue: 2
                onMoved: (val) => {
                    NiriSettingsService.shadowSoftness = Math.round(val);
                }
            }

        }

    }

}
