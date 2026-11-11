import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Utils
import qs.Modules.Settings.Components

AppContainer {
    id: barSettingsRoot

    AppGroup {
        title: "Скрытые значки трея"
        icon: "eye-off"

        ThemedText {
            Layout.fillWidth: true
            visible: SettingsService.hiddenTrayItems.length === 0
            text: "Скрытых значков нет"
            color: Theme.muted
        }

        Repeater {
            model: SettingsService.hiddenTrayItems

            RowLayout {
                id: hiddenRow

                required property var modelData

                Layout.fillWidth: true
                spacing: Constants.sizeSm

                ThemedText {
                    Layout.fillWidth: true
                    text: hiddenRow.modelData.name
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }

                SvgIconButton {
                    icon: "eye"
                    iconSize: Constants.sizeSm
                    iconColor: Theme.accent
                    textIcon: "Вернуть"
                    textIconSize: 12
                    useCustomWidth: true
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton)
                            SettingsService.restoreTrayItem(hiddenRow.modelData.id);
                    }
                }
            }
        }
    }

    AppGroup {
        title: "Стиль панели"
        icon: "bar"

        SettingSegmented {
            label: "Стиль"
            description: "Convex или Island"
            model: [{
                "text": "Convex",
                "value": "convex"
            }, {
                "text": "Island",
                "value": "island"
            }]
            currentValue: SettingsService.barStyle
            onActivated: (value) => {
                SettingsService.barStyle = value;
            }
        }

    }

    // ISLAND MODE WIDGETS
    AppGroup {
        title: "Виджеты панели Island"
        icon: "widgets"
        visible: SettingsService.barIslandMode

        SettingSegmented {
            label: "Правый круглый остров"
            description: "Что показывать в правом круглом острове: обложку музыки или центр управления"
            model: [{
                "text": "Авто (музыка или настройки)",
                "value": "auto"
            }, {
                "text": "Всегда музыка",
                "value": "music"
            }, {
                "text": "Всегда центр управления",
                "value": "control_center"
            }]
            currentValue: SettingsService.islandRightMode
            onActivated: (value) => {
                SettingsService.islandRightMode = value;
            }
        }

    }

    AppGroup {
        title: "Формат часов"
        icon: "clock"

        SettingToggle {
            label: "24-часовой формат"
            description: "24 часа вместо 12-часового AM/PM"
            checked: SettingsService.clock24h
            onCheckedChanged: {
                SettingsService.clock24h = checked;
            }
        }

        SettingToggle {
            label: "Показывать секунды"
            description: "Секунды на основных часах"
            checked: SettingsService.clockSeconds
            onCheckedChanged: {
                SettingsService.clockSeconds = checked;
            }
        }

        SettingToggle {
            label: "Показывать дату"
            description: "Текущая дата рядом с часами"
            checked: SettingsService.clockShowDate
            onCheckedChanged: {
                SettingsService.clockShowDate = checked;
            }
        }

    }

    AppGroup {
        title: "Рабочие столы"
        icon: "slider"

        SettingSpinBox {
            label: "Количество рабочих столов"
            description: "Сколько рабочих столов показывать на панели"
            value: SettingsService.numberOfWorkspaces
            from: 1
            to: 20
            stepSize: 1
            decimals: 0
            suffix: ""
            onMoved: (val) => {
                SettingsService.numberOfWorkspaces = val;
            }
        }

    }

}
