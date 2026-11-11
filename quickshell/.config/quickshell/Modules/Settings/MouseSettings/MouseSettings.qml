import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    property var availableCursors: []

    Process {
        id: fetchCursorsProc

        command: ["sh", "-c", "find /usr/share/icons ~/.local/share/icons ~/.icons -type d -name 'cursors' 2>/dev/null | awk -F'/' '{print $(NF-1)}' | sort -u"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (data) {
                    let lines = data.split('\n').map((x) => {
                        return x.trim();
                    }).filter((x) => {
                        return x !== "";
                    });
                    let arr = root.availableCursors.slice();
                    let changed = false;
                    lines.forEach((l) => {
                        if (arr.indexOf(l) === -1) {
                            arr.push(l);
                            changed = true;
                        }
                    });
                    if (arr.indexOf(SettingsService.cursorTheme) === -1 && SettingsService.cursorTheme) {
                        arr.unshift(SettingsService.cursorTheme);
                        changed = true;
                    }
                    if (changed)
                        root.availableCursors = arr;

                }
            }
        }

    }

    AppGroup {
        title: "Указатель"
        icon: "cursor"

        SettingSpinBox {
            label: "Чувствительность указателя"
            description: "Скорость указателя: от -1.0 (медленно) до 1.0 (быстро)"
            from: -1
            to: 1
            stepSize: 0.05
            value: NiriSettingsService.mouseSensitivity
            defaultValue: 0
            decimals: 2
            onMoved: (val) => {
                NiriSettingsService.mouseSensitivity = Number(val.toFixed(2));
            }
        }

        SettingSegmented {
            label: "Ускорение"
            description: "«Без ускорения» — движение 1:1 с мышью"
            model: [{
                "text": "Без ускорения (1:1)",
                "value": "flat"
            }, {
                "text": "Адаптивное",
                "value": "adaptive"
            }]
            currentValue: NiriSettingsService.mouseAccelProfile === "flat" ? "flat" : "adaptive"
            onActivated: (val) => {
                NiriSettingsService.mouseAccelProfile = val;
            }
        }

        SettingToggle {
            id: leftHandedToggle

            label: "Мышь для левши"
            description: "Поменять местами левую и правую кнопки"
            checked: NiriSettingsService.mouseLeftHanded
            onCheckedChanged: {
                if (checked !== NiriSettingsService.mouseLeftHanded)
                    NiriSettingsService.mouseLeftHanded = checked;

            }

            Binding {
                target: leftHandedToggle
                property: "checked"
                value: NiriSettingsService.mouseLeftHanded
            }

        }

    }

    AppGroup {
        title: "Прокрутка"
        icon: "reload"

        SettingToggle {
            id: naturalScrollToggle

            label: "Естественная прокрутка"
            description: "Обратное направление колёсика"
            checked: NiriSettingsService.mouseNaturalScroll
            onCheckedChanged: {
                if (checked !== NiriSettingsService.mouseNaturalScroll)
                    NiriSettingsService.mouseNaturalScroll = checked;

            }

            Binding {
                target: naturalScrollToggle
                property: "checked"
                value: NiriSettingsService.mouseNaturalScroll
            }

        }

        SettingSpinBox {
            label: "Скорость прокрутки"
            description: "Множитель скорости колёсика"
            from: 0.2
            to: 3
            stepSize: 0.1
            defaultValue: 1
            suffix: "x"
            decimals: 1
            value: NiriSettingsService.mouseScrollFactor
            onMoved: (val) => {
                NiriSettingsService.mouseScrollFactor = Number(val.toFixed(1));
            }
        }

    }

    AppGroup {
        title: "Курсор и фокус"
        icon: "cursor"

        ThemedSelect {
            id: cursorSelect

            function updateSelection() {
                for (let i = 0; i < root.availableCursors.length; i++) {
                    if (root.availableCursors[i] === SettingsService.cursorTheme) {
                        cursorSelect.currentIndex = i;
                        return ;
                    }
                }
            }

            label: "Тема курсора"
            description: "Тема указателя для всей системы"
            comboWidth: 260
            searchable: true
            model: root.availableCursors
            Component.onCompleted: updateSelection()
            onModelChanged: updateSelection()
            onActivated: (index) => {
                let newTheme = model[index];
                if (SettingsService.cursorTheme !== newTheme)
                    SettingsService.cursorTheme = newTheme;

            }

            Connections {
                function onCursorThemeChanged() {
                    cursorSelect.updateSelection();
                }

                target: SettingsService
            }

        }

        SettingSegmented {
            label: "Размер курсора"
            description: "Размер указателя в пикселях"
            model: [{
                "text": "16",
                "value": 16
            }, {
                "text": "20",
                "value": 20
            }, {
                "text": "24",
                "value": 24
            }, {
                "text": "32",
                "value": 32
            }, {
                "text": "48",
                "value": 48
            }, {
                "text": "64",
                "value": 64
            }]
            currentValue: SettingsService.cursorSize
            onActivated: (value) => {
                SettingsService.cursorSize = value;
            }
        }

        SettingSpinBox {
            label: "Скрывать курсор"
            description: "Через сколько секунд бездействия прятать курсор (0 — не прятать)"
            from: 0
            to: 60
            stepSize: 1
            decimals: 0
            allowOff: true
            offText: "Никогда"
            suffix: "s"
            value: NiriSettingsService.cursorInactiveTimeout
            defaultValue: 5
            onMoved: (val) => {
                NiriSettingsService.cursorInactiveTimeout = Math.round(val);
            }
        }

        SettingSegmented {
            label: "Фокус окон"
            description: "Переходит ли фокус за курсором или нужен клик"
            model: [{
                "text": "За курсором",
                "value": 1
            }, {
                "text": "По клику",
                "value": 0
            }]
            currentValue: NiriSettingsService.mouseFollowMouse
            onActivated: (val) => {
                NiriSettingsService.mouseFollowMouse = val;
            }
        }

    }

    AppGroup {
        title: "Тачпад"
        icon: "touchpad"

        SettingToggle {
            id: tapToClickToggle

            label: "Касание — клик"
            description: "Клик касанием одним пальцем"
            checked: NiriSettingsService.touchpadTapToClick
            onCheckedChanged: {
                if (checked !== NiriSettingsService.touchpadTapToClick)
                    NiriSettingsService.touchpadTapToClick = checked;

            }

            Binding {
                target: tapToClickToggle
                property: "checked"
                value: NiriSettingsService.touchpadTapToClick
            }

        }

        SettingToggle {
            id: touchpadNaturalScrollToggle

            label: "Естественная прокрутка тачпада"
            description: "Содержимое движется за двумя пальцами"
            checked: NiriSettingsService.touchpadNaturalScroll
            onCheckedChanged: {
                if (checked !== NiriSettingsService.touchpadNaturalScroll)
                    NiriSettingsService.touchpadNaturalScroll = checked;

            }

            Binding {
                target: touchpadNaturalScrollToggle
                property: "checked"
                value: NiriSettingsService.touchpadNaturalScroll
            }

        }

        SettingToggle {
            id: disableWhileTypingToggle

            label: "Отключать при наборе текста"
            description: "Защита от случайных касаний во время печати"
            checked: NiriSettingsService.touchpadDisableWhileTyping
            onCheckedChanged: {
                if (checked !== NiriSettingsService.touchpadDisableWhileTyping)
                    NiriSettingsService.touchpadDisableWhileTyping = checked;

            }

            Binding {
                target: disableWhileTypingToggle
                property: "checked"
                value: NiriSettingsService.touchpadDisableWhileTyping
            }

        }

    }

}
