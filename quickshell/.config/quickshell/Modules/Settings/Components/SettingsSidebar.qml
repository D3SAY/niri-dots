import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

AppSidebar {
    id: sidebarRoot

    property int activeTab: 0

    signal tabClicked(int index)

    title: "НАСТРОЙКИ"
    subtitle: "ПАРАМЕТРЫ И НАСТРОЙКА"

    // Section 1: DESKTOP
    ThemedText {
        text: "РАБОЧИЙ СТОЛ"
        customSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.8
        color: Theme.muted
        Layout.leftMargin: Constants.sizeLg
        Layout.topMargin: Constants.size2Xs
        Layout.bottomMargin: Constants.size2Xs
    }

    // Appearance (Tab 0)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "color-palette"
            labelText: "Оформление"
            isActive: sidebarRoot.activeTab === 0
            onRowClicked: sidebarRoot.tabClicked(0)
        }

    }

    // Wallpaper (Tab 8)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "picture"
            labelText: "Обои"
            isActive: sidebarRoot.activeTab === 8
            onRowClicked: sidebarRoot.tabClicked(8)
        }

    }

    // Desktop Bar (Tab 1)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "bar"
            labelText: "Панель"
            isActive: sidebarRoot.activeTab === 1
            onRowClicked: sidebarRoot.tabClicked(1)
        }

    }

    // Visual Effects (Tab 2)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "sparkles"
            labelText: "Эффекты"
            isActive: sidebarRoot.activeTab === 2
            onRowClicked: sidebarRoot.tabClicked(2)
        }

    }

    // Windows & Display (Tab 3)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "monitor"
            labelText: "Окна и экран"
            isActive: sidebarRoot.activeTab === 3
            onRowClicked: sidebarRoot.tabClicked(3)
        }

    }

    // Section 2: INPUT & HARDWARE
    ThemedText {
        text: "ВВОД И УСТРОЙСТВА"
        customSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.8
        color: Theme.muted
        Layout.leftMargin: Constants.sizeLg
        Layout.topMargin: Constants.sizeSm
        Layout.bottomMargin: Constants.size2Xs
    }

    // Mouse & Touchpad (Tab 5)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "cursor"
            labelText: "Мышь и тачпад"
            isActive: sidebarRoot.activeTab === 5
            onRowClicked: sidebarRoot.tabClicked(5)
        }

    }

    // Keyboard & Clipboard (Tab 6)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "keyboard"
            labelText: "Клавиатура и буфер"
            isActive: sidebarRoot.activeTab === 6
            onRowClicked: sidebarRoot.tabClicked(6)
        }

    }

    // Keybinds (Tab 9)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "keybinds-icon"
            labelText: "Горячие клавиши"
            isActive: sidebarRoot.activeTab === 9
            onRowClicked: sidebarRoot.tabClicked(9)
        }

    }

    // Section 3: MANAGEMENT
    ThemedText {
        text: "УПРАВЛЕНИЕ"
        customSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.8
        color: Theme.muted
        Layout.leftMargin: Constants.sizeLg
        Layout.topMargin: Constants.sizeSm
        Layout.bottomMargin: Constants.size2Xs
    }

    // Integrations & Apps (Tab 4)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "apps"
            labelText: "Интеграции"
            isActive: sidebarRoot.activeTab === 4
            onRowClicked: sidebarRoot.tabClicked(4)
        }

    }

    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "rocket"
            labelText: "Автозапуск"
            isActive: sidebarRoot.activeTab === 10
            onRowClicked: sidebarRoot.tabClicked(10)
        }
    }

    // Section 4: ABOUT
    ThemedText {
        text: "О СИСТЕМЕ"
        customSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.8
        color: Theme.muted
        Layout.leftMargin: Constants.sizeLg
        Layout.topMargin: Constants.sizeSm
        Layout.bottomMargin: Constants.size2Xs
    }

    // About System (Tab 7 - System Info)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "info"
            labelText: "О системе"
            isActive: sidebarRoot.activeTab === 7
            onRowClicked: sidebarRoot.tabClicked(7)
        }

    }

    Item {
        Layout.preferredHeight: Constants.sizeMd
    }

}
