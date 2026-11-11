import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

AppHeader {
    id: headerRoot

    required property var managerRoot
    property var contentComp: null
    readonly property alias searchField: searchField

    title: {
        if (managerRoot.actionMode === "install")
            return managerRoot.selectedCategory === "featured" ? "Обзор пакетов" : (({ "internet": "Интернет", "development": "Разработка", "multimedia": "Мультимедиа", "gaming": "Игры", "utilities": "Утилиты", "office": "Офис" })[managerRoot.selectedCategory] || managerRoot.selectedCategory);

        if (managerRoot.actionMode === "remove")
            return "Установленные пакеты";

        return "Обновления системы";
    }
    category: "PACMAN И AUR"
    subtitle: {
        if (managerRoot.isSearching)
            return "Поиск пакетов…";

        if (managerRoot.actionMode === "update")
            return managerRoot.allResults.length > 0 ? ("Доступно обновлений: " + managerRoot.allResults.length) : "Все пакеты обновлены";

        if (managerRoot.searchText.length > 0)
            return "Найдено пакетов: " + managerRoot.resultsModel.count;

        if (managerRoot.actionMode === "remove")
            return "Установлено пакетов: " + managerRoot.resultsModel.count;

        return "Подборка программ из репозиториев и AUR";
    }
    showDivider: true

    Rectangle {
        visible: managerRoot.actionMode !== "update"
        Layout.preferredWidth: 260
        Layout.preferredHeight: 34
        color: "transparent"
        Layout.alignment: Qt.AlignVCenter

        ThemedSearchBar {
            id: searchField

            anchors.fill: parent
            customSize: Constants.sizeSm
            placeholderText: managerRoot.actionMode === "remove" ? "Поиск среди установленных (/)…" : "Поиск для установки (/)…"
            text: managerRoot.searchText
            onSearchRequested: (text) => {
                managerRoot.searchText = text;
                managerRoot.stopSearchTimers();
                managerRoot.restartDebounceTimer();
            }
            textField.onTextChanged: {
                if (searchField.textField.text.length > 0 && !searchField.textField.activeFocus)
                    searchField.textField.forceActiveFocus();

            }
            textField.Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    if (managerRoot.searchText !== "") {
                        managerRoot.searchText = "";
                        event.accepted = true;
                        return ;
                    }
                    if (headerRoot.contentComp)
                        headerRoot.contentComp.focusListView();
                    else
                        searchField.textField.focus = false;
                    event.accepted = true;
                    return ;
                }
                managerRoot.handleKeyPress(event, true);
            }
        }

    }

}
