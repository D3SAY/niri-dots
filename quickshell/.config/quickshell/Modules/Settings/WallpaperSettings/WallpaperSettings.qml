import "Components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: wallpaperRoot

    AppGroup {
        title: "Кадрирование"
        icon: "picture-spark"
        showDividers: false

        WallpaperCropPreview {
            Layout.fillWidth: true
        }

        SettingSegmented {
            label: "Масштабирование"
            description: "Как обои подстраиваются под соотношение сторон"
            model: [{
                "text": "Обрезать",
                "value": "crop"
            }, {
                "text": "Вписать",
                "value": "fit"
            }, {
                "text": "Растянуть",
                "value": "stretch"
            }]
            currentValue: NiriSettingsService.wpResizeMode
            onActivated: (val) => {
                NiriSettingsService.wpResizeMode = val;
            }
        }

    }

    AppGroup {
        title: "Смена и переходы"
        icon: "sparkles"

        SettingToggle {
            id: autoShuffleToggle

            label: "Менять обои автоматически"
            onCheckedChanged: {
                if (checked !== NiriSettingsService.wpAutoShuffle)
                    NiriSettingsService.wpAutoShuffle = checked;

            }

            Binding {
                target: autoShuffleToggle
                property: "checked"
                value: NiriSettingsService.wpAutoShuffle
            }

        }

        SettingSpinBox {
            enabled: NiriSettingsService.wpAutoShuffle
            opacity: enabled ? 1 : 0.5
            label: "Интервал смены"
            description: "Считается от последней смены обоев"
            from: 1
            to: 1440
            stepSize: 30
            value: NiriSettingsService.wpShuffleInterval
            suffix: " мин"
            decimals: 0
            onMoved: (val) => {
                NiriSettingsService.wpShuffleInterval = Math.round(val);
            }
        }

        ThemedSelect {
            label: "Тип перехода"
            model: ["none", "grow", "fade", "wipe", "wave", "random"]
            textMap: ({
                "none": "Без перехода",
                "grow": "Рост",
                "fade": "Затухание",
                "wipe": "Шторка",
                "wave": "Волна",
                "random": "Случайно"
            })
            currentIndex: {
                if (!NiriSettingsService.wpEnableTransitions)
                    return 0;

                let idx = model.indexOf(NiriSettingsService.wpTransitionType);
                return idx !== -1 ? idx : 1;
            }
            onActivated: (index) => {
                let val = model[index];
                if (val === "none") {
                    NiriSettingsService.wpEnableTransitions = false;
                } else {
                    NiriSettingsService.wpEnableTransitions = true;
                    NiriSettingsService.wpTransitionType = val;
                }
            }
        }

        ThemedSelect {
            label: "Точка перехода"
            model: ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"]
            textMap: ({
                "top-left": "Слева сверху",
                "top": "Сверху",
                "top-right": "Справа сверху",
                "left": "Слева",
                "center": "По центру",
                "right": "Справа",
                "bottom-left": "Слева снизу",
                "bottom": "Снизу",
                "bottom-right": "Справа снизу"
            })
            currentIndex: {
                let idx = model.indexOf(NiriSettingsService.wpTransitionPos);
                return idx !== -1 ? idx : 4;
            }
            onActivated: (index) => {
                NiriSettingsService.wpTransitionPos = model[index];
            }
            enabled: NiriSettingsService.wpEnableTransitions && NiriSettingsService.wpTransitionType !== "random"
            opacity: enabled ? 1 : 0.4

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ColumnLayout {
            spacing: Constants.sizeLg
            Layout.fillWidth: true
            enabled: NiriSettingsService.wpEnableTransitions
            opacity: enabled ? 1 : 0.4

            SettingSegmented {
                label: "Скорость перехода"
                model: [{
                    "text": "Медленно",
                    "value": 60
                }, {
                    "text": "Обычно",
                    "value": 120
                }, {
                    "text": "Быстро",
                    "value": 180
                }, {
                    "text": "Мгновенно",
                    "value": 240
                }]
                currentValue: NiriSettingsService.wpTransitionStep
                onActivated: (val) => {
                    NiriSettingsService.wpTransitionStep = val;
                }
            }

            Divider {
            }

            SettingSegmented {
                label: "Частота кадров перехода"
                model: [{
                    "text": "30",
                    "value": 30
                }, {
                    "text": "60",
                    "value": 60
                }, {
                    "text": "120",
                    "value": 120
                }, {
                    "text": "144",
                    "value": 144
                }]
                currentValue: NiriSettingsService.wpTransitionFps
                onActivated: (val) => {
                    NiriSettingsService.wpTransitionFps = val;
                }
            }

            Divider {
                visible: NiriSettingsService.wpTransitionType === "wipe" || NiriSettingsService.wpTransitionType === "wave"
            }

            ThemedSlider {
                label: "Угол перехода"
                from: 0
                to: 360
                stepSize: 10
                value: NiriSettingsService.wpTransitionAngle
                suffix: "°"
                decimals: 0
                visible: NiriSettingsService.wpTransitionType === "wipe" || NiriSettingsService.wpTransitionType === "wave"
                onMoved: (val) => {
                    NiriSettingsService.wpTransitionAngle = Math.round(val);
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
