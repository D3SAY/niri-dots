import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

AppSidebar {
    id: sidebarRoot

    required property var managerRoot

    title: "ПАКЕТЫ"
    subtitle: "ПРОГРАММЫ И ОБНОВЛЕНИЯ"

    ThemedText {
        text: "РЕЖИМЫ"
        customSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.8
        color: Theme.muted
        Layout.leftMargin: Constants.sizeLg
        Layout.topMargin: Constants.size2Xs
        Layout.bottomMargin: Constants.size2Xs
    }

    // Mode 1: Discover
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "rocket"
            labelText: "Обзор"
            statusText: ""
            isActive: managerRoot.actionMode === "install"
            onRowClicked: managerRoot.switchMode("install")
        }

    }

    // Mode 2: Installed
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "box"
            labelText: "Установленные"
            statusText: managerRoot.actionMode === "remove" && managerRoot.resultsModel.count > 0 ? (managerRoot.resultsModel.count + "") : ""
            isActive: managerRoot.actionMode === "remove"
            onRowClicked: managerRoot.switchMode("remove")
        }

    }

    // Mode 3: Updates
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "update"
            labelText: "Обновления"
            statusText: {
                if (managerRoot.actionMode === "update" && managerRoot.allResults.length > 0)
                    return managerRoot.allResults.length + "";

                return "";
            }
            isActive: managerRoot.actionMode === "update"
            onRowClicked: managerRoot.switchMode("update")
        }

    }

    // Categories Section (Featured for Discover Mode)
    ThemedText {
        visible: managerRoot.actionMode === "install"
        text: "ПОДБОРКА"
        customSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.8
        color: Theme.muted
        Layout.leftMargin: Constants.sizeLg
        Layout.topMargin: Constants.sizeMd
        Layout.bottomMargin: Constants.size2Xs
    }

    Repeater {
        model: managerRoot.actionMode === "install" ? [{
            "label": "Вся подборка",
            "val": "featured",
            "icon": "sparkles"
        }, {
            "label": "Интернет",
            "val": "internet",
            "icon": "wifi"
        }, {
            "label": "Разработка",
            "val": "development",
            "icon": "code"
        }, {
            "label": "Мультимедиа",
            "val": "multimedia",
            "icon": "music"
        }, {
            "label": "Игры",
            "val": "gaming",
            "icon": "gamepad"
        }, {
            "label": "Утилиты",
            "val": "utilities",
            "icon": "tune"
        }, {
            "label": "Офис",
            "val": "office",
            "icon": "clipboard"
        }] : []

        Item {
            Layout.fillWidth: true
            Layout.leftMargin: Constants.sizeSm
            Layout.rightMargin: Constants.sizeSm
            Layout.preferredHeight: 34

            SidebarNavRow {
                anchors.fill: parent
                iconName: modelData.icon
                labelText: modelData.label
                isActive: managerRoot.selectedCategory === modelData.val && managerRoot.searchText === ""
                onRowClicked: managerRoot.switchCategory(modelData.val)
            }

        }

    }

    Item {
        Layout.preferredHeight: Constants.sizeMd
    }

}
