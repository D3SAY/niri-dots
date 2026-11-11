import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Settings.BarSettings
import qs.Modules.Settings.Components
import qs.Modules.Settings.EffectsSettings
import qs.Modules.Settings.InputAndClipboardSettings
import qs.Modules.Settings.KeybindsSettings
import qs.Modules.Settings.IntegrationsSettings
import qs.Modules.Settings.MouseSettings
import qs.Modules.Settings.PersonalizationSettings
import qs.Modules.Settings.SystemInfo
import qs.Modules.Settings.WallpaperSettings
import qs.Modules.Settings.WindowSettings

AppWindow {
    id: root

    property var pageComponents: [personalizationComp, barSettingsComp, effectsComp, windowComp, integrationsComp, mouseComp, inputAndClipboardComp, systemInfoComp, wallpaperComp, keybindsComp, autostartComp]
    property int activeTab: 0
    readonly property var navOrder: [0, 8, 1, 2, 3, 5, 6, 9, 4, 10, 7]
    readonly property var tabMetadata: ({
        "0": {
            "title": "Оформление",
            "subtitle": "Темы, цвета из обоев и системные шрифты",
            "category": "РАБОЧИЙ СТОЛ"
        },
        "1": {
            "title": "Панель",
            "subtitle": "Виджеты, расположение, стиль и видимость панели",
            "category": "РАБОЧИЙ СТОЛ"
        },
        "2": {
            "title": "Эффекты",
            "subtitle": "Размытие, прозрачность, анимации окон и тени",
            "category": "РАБОЧИЙ СТОЛ"
        },
        "3": {
            "title": "Окна и экран",
            "subtitle": "Правила окон, рамки, отступы и мониторы",
            "category": "РАБОЧИЙ СТОЛ"
        },
        "4": {
            "title": "Интеграции и приложения",
            "subtitle": "Погода, уведомления и запуск приложений",
            "category": "УПРАВЛЕНИЕ"
        },
        "5": {
            "title": "Мышь и тачпад",
            "subtitle": "Скорость курсора, ускорение, прокрутка и жесты тачпада",
            "category": "ВВОД И УСТРОЙСТВА"
        },
        "6": {
            "title": "Клавиатура и буфер обмена",
            "subtitle": "Раскладки, задержка повтора и история буфера обмена",
            "category": "ВВОД И УСТРОЙСТВА"
        },
        "7": {
            "title": "О системе",
            "subtitle": "Железо, ядро и программное окружение",
            "category": "О СИСТЕМЕ"
        },
        "8": {
            "title": "Обои",
            "subtitle": "Кадрирование, масштаб, переходы и случайный порядок",
            "category": "РАБОЧИЙ СТОЛ"
        },
        "9": {
            "title": "Горячие клавиши",
            "subtitle": "Все комбинации niri: изменить, выключить, удалить, сменить категорию или добавить свою",
            "category": "ВВОД И УСТРОЙСТВА"
        },
        "10": {
            "title": "Автозапуск",
            "subtitle": "Добавляйте и отключайте приложения, запускаемые при входе",
            "category": "УПРАВЛЕНИЕ"
        }
    })
    readonly property var currentTabMeta: tabMetadata[activeTab] || tabMetadata[0]

    widgetId: "minflair_settings"
    windowTitle: "Настройки Minflair"
    contentPadding: 0
    onIsOpenChanged: {
        if (isOpen) {
            if (AppState.pendingSettingsTab !== -1) {
                activeTab = AppState.pendingSettingsTab;
                AppState.pendingSettingsTab = -1;
            } else {
                activeTab = 0;
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        SettingsSidebar {
            id: sidebar

            Layout.fillHeight: true
            activeTab: root.activeTab
            onTabClicked: (id) => {
                root.activeTab = id;
            }
        }

        ColumnLayout {
            id: contentContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            AppHeader {
                title: root.currentTabMeta.title
                category: root.currentTabMeta.category
                subtitle: root.currentTabMeta.subtitle
                showDivider: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                PageTransitionView {
                    anchors.fill: parent
                    activeIndex: root.activeTab
                    order: root.navOrder
                    onContentNeedsUpdate: (index) => {
                        pageLoader.sourceComponent = root.pageComponents[index];
                    }

                    Loader {
                        id: pageLoader

                        anchors.fill: parent
                        sourceComponent: personalizationComp
                    }

                }

            }

        }

    }

    Shortcut {
        sequence: "Ctrl+Tab"
        enabled: root.isOpen && root.pageComponents && root.pageComponents.length > 1
        onActivated: {
            let currentIdx = root.navOrder.indexOf(root.activeTab);
            if (currentIdx === -1)
                currentIdx = 0;

            let nextIdx = (currentIdx + 1) % root.navOrder.length;
            root.activeTab = root.navOrder[nextIdx];
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        enabled: root.isOpen && root.pageComponents && root.pageComponents.length > 1
        onActivated: {
            let currentIdx = root.navOrder.indexOf(root.activeTab);
            if (currentIdx === -1)
                currentIdx = 0;

            let prevIdx = (currentIdx - 1 + root.navOrder.length) % root.navOrder.length;
            root.activeTab = root.navOrder[prevIdx];
        }
    }

    Component {
        id: personalizationComp

        PersonalizationSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: barSettingsComp

        BarSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: effectsComp

        EffectsSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: windowComp

        WindowSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: integrationsComp

        IntegrationsSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: mouseComp

        MouseSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: inputAndClipboardComp

        InputAndClipboardSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: systemInfoComp

        SystemInfo {
            anchors.fill: parent
        }

    }

    Component {
        id: wallpaperComp

        WallpaperSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: keybindsComp

        KeybindsSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: autostartComp

        AutostartSettings {
            anchors.fill: parent
        }
    }

}
