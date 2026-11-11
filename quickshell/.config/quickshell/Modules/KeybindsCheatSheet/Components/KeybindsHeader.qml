import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

AppHeader {
    id: headerRoot

    required property var keybindsRoot
    readonly property alias searchField: searchField

    title: keybindsRoot.selectedCategory === "All" ? "Все сочетания" : keybindsRoot.selectedCategory
    category: "NIRI"
    subtitle: keybindsRoot.searchText !== "" ? ("Найдено: " + keybindsRoot.displayedBinds.length) : (keybindsRoot.selectedCategory === "All" ? ("Всего сочетаний: " + keybindsRoot.totalKeybinds) : ("В этой категории: " + keybindsRoot.categoryBindCount(keybindsRoot.selectedCategory)))
    showDivider: true

    Rectangle {
        Layout.preferredWidth: 260
        Layout.preferredHeight: 34
        color: "transparent"
        Layout.alignment: Qt.AlignVCenter

        ThemedSearchBar {
            id: searchField

            anchors.fill: parent
            customSize: Constants.sizeSm
            placeholderText: "Поиск сочетаний (/)…"
            text: keybindsRoot.searchText
            onSearchRequested: (text) => {
                keybindsRoot.searchText = text;
            }
            textField.Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    if (keybindsRoot.searchText !== "") {
                        keybindsRoot.searchText = "";
                        event.accepted = true;
                    }
                }
            }
        }

    }

}
