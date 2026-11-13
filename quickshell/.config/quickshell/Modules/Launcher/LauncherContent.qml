import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Launcher.Components

Item {
    id: root

    property var widget: null
    property string searchText: ""
    property var allApps: []
    property var filteredApps: []
    property alias initialFocusItem: searchField
    property int maxVisibleItems: 8
    readonly property bool isSearching: searchField.text.trim() !== ""
    readonly property var calculation: calculate(searchField.text)
    property bool resultCopied: false
    onCalculationChanged: resultCopied = false
    readonly property int currentResultsCount: root.filteredApps ? root.filteredApps.length : 0
    readonly property int targetVisibleItems: {
        if (!isSearching)
            return maxVisibleItems;

        if (currentResultsCount === 0)
            return maxVisibleItems;

        return Math.min(currentResultsCount, maxVisibleItems);
    }
    property int visibleItems: targetVisibleItems
    property int preferredContentWidth: 700
    readonly property int searchBarHeight: Constants.size4Xl
    readonly property int itemHeight: 44
    readonly property int listSpacing: Constants.sizeXs
    readonly property int layoutSpacing: Constants.sizeSm
    readonly property int maxListHeight: (maxVisibleItems * itemHeight) + Math.max(0, (maxVisibleItems - 1) * listSpacing)
    readonly property int baseListHeight: (targetVisibleItems * itemHeight) + Math.max(0, (targetVisibleItems - 1) * listSpacing)
    readonly property int expandedExtraHeight: {
        if (typeof appsView !== "undefined" && appsView && appsView.expandedIndex >= 0 && root.filteredApps && appsView.expandedIndex < root.filteredApps.length) {
            let app = root.filteredApps[appsView.expandedIndex];
            if (app && app.actions && app.actions.length > 0) {
                let n = app.actions.length;
                return (n * 34) + Math.max(0, (n - 1) * 4) + Constants.sizeXs;
            }
        }
        return 0;
    }
    readonly property int visibleListHeight: {
        if (calculation)
            return itemHeight + layoutSpacing;

        if (!isSearching)
            return maxListHeight + Math.min(expandedExtraHeight, 200);

        if (currentResultsCount === 0)
            return maxListHeight;

        let needed = baseListHeight + expandedExtraHeight;
        let maxAllowed = maxListHeight + Math.min(expandedExtraHeight, 200);
        return Math.min(needed, maxAllowed);
    }

    function calculate(query) {
        const input = query.trim();
        const explicit = input.startsWith("=");
        const expression = (explicit ? input.slice(1) : input)
            .replace(/,/g, ".").replace(/[×хХ]/g, "*").replace(/÷/g, "/").replace(/−/g, "-").trim();
        if (!explicit && (!/^[\d\s.+*/%^()-]+$/.test(expression) || !/\d/.test(expression)
                || !/[+*/%^()-]/.test(expression)))
            return null;
        if (!expression)
            return { error: "Введи выражение" };
        if (expression.length > 256)
            return { error: "Выражение слишком длинное" };

        const tokens = expression.match(/(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|\S/g);
        const precedence = { "+": 1, "-": 1, "*": 2, "/": 2, "%": 2, "^": 3 };
        let index = 0;

        function parse(minimum) {
            const token = tokens[index++];
            let value;
            if (token === "(") {
                value = parse(1);
                if (tokens[index++] !== ")")
                    throw new Error("Не хватает закрывающей скобки");
            } else if (token === "+" || token === "-") {
                value = (token === "-" ? -1 : 1) * parse(3);
            } else if (token && /^\.?\d/.test(token)) {
                value = Number(token);
            } else {
                throw new Error("Проверь выражение");
            }

            while (index < tokens.length) {
                const operator = tokens[index];
                const level = precedence[operator];
                if (!level || level < minimum)
                    break;
                index++;
                const right = parse(operator === "^" ? level : level + 1);
                switch (operator) {
                case "+": value += right; break;
                case "-": value -= right; break;
                case "*": value *= right; break;
                case "/":
                case "%":
                    if (right === 0)
                        throw new Error("Деление на ноль");
                    value = operator === "/" ? value / right : value % right;
                    break;
                case "^": value = Math.pow(value, right); break;
                }
            }
            return value;
        }

        try {
            const value = parse(1);
            if (index !== tokens.length)
                throw new Error("Проверь выражение");
            if (!Number.isFinite(value))
                throw new Error("Результат вне допустимого диапазона");
            return { value: String(Number(value.toPrecision(15))) };
        } catch (error) {
            return explicit ? { error: error.message } : null;
        }
    }

    function copyResult() {
        if (calculation && calculation.value !== undefined && !copyProcess.running) {
            copyProcess.command = ["wl-copy", "--", calculation.value];
            copyProcess.running = true;
        }
    }

    function filterApps(query) {
        query = query.toLowerCase();
        let newFiltered = [];
        for (let i = 0; i < root.allApps.length; i++) {
            let app = root.allApps[i];
            if (app.name.toLowerCase().includes(query))
                newFiltered.push(app);

        }
        root.filteredApps = newFiltered;
        if (appsView) {
            appsView.expandedIndex = -1;
            if (root.filteredApps.length > 0)
                appsView.currentIndex = 0;
            else
                appsView.currentIndex = -1;
        }
    }

    function handleKeyPress(event, fromSearch) {
        if (calculation && event.key !== Qt.Key_Escape) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                copyResult();
                event.accepted = true;
            }
            return;
        }
        let currentDelegate = appsView.currentItem;
        if (event.key === Qt.Key_Down) {
            if (currentDelegate && currentDelegate.isExpanded && currentDelegate.currentActionIndex < currentDelegate.actionCount - 1) {
                currentDelegate.currentActionIndex++;
                event.accepted = true;
            } else if (appsView.count > 0) {
                appsView.expandedIndex = -1;
                appsView.currentIndex = Math.min(appsView.count - 1, appsView.currentIndex + 1);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Up) {
            if (currentDelegate && currentDelegate.isExpanded && currentDelegate.currentActionIndex >= 0) {
                currentDelegate.currentActionIndex--;
                event.accepted = true;
            } else if (appsView.count > 0) {
                appsView.expandedIndex = -1;
                appsView.currentIndex = Math.max(0, appsView.currentIndex - 1);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Right) {
            if (currentDelegate && currentDelegate.hasActions && !currentDelegate.isExpanded) {
                appsView.expandedIndex = appsView.currentIndex;
                currentDelegate.currentActionIndex = 0;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Left) {
            if (currentDelegate && currentDelegate.isExpanded) {
                appsView.expandedIndex = -1;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            let idx = appsView.currentIndex >= 0 ? appsView.currentIndex : 0;
            if (root.filteredApps.length > idx) {
                if (currentDelegate && currentDelegate.isExpanded && currentDelegate.currentActionIndex >= 0) {
                    let action = root.filteredApps[idx].actions[currentDelegate.currentActionIndex];
                    launchApp(action.argv, false);
                } else {
                    let app = root.filteredApps[idx];
                    launchApp(app.argv, app.terminal);
                }
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Escape) {
            if (root.widget && typeof root.widget.close === "function")
                root.widget.close();
            else if (root.widget && root.widget.isOpen !== undefined)
                root.widget.isOpen = false;
            else
                AppState.activeWidget = "";
            event.accepted = true;
        }
    }

    function launchApp(argv, terminal) {
        if (!argv || !argv.length)
            return ;

        const command = terminal ? ["ghostty", "--gtk-single-instance=false", "-e"].concat(argv) : argv;

        appLauncher.running = false;
        appLauncher.command = command;
        appLauncher.startDetached();
        AppState.closeAllWidgets();
        if (root.widget && root.widget.close !== undefined)
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
    }

    function resetLauncher() {
        if (appsView)
            appsView.expandedIndex = -1;

        searchField.text = "";
        if (AppState.launcherApps && AppState.launcherApps.length > 0) {
            root.allApps = AppState.launcherApps;
            filterApps("");
        }
        // Refresh on every open so installs and removals appear without restarting
        // Quickshell. The cached list remains visible until the refresh completes.
        loadAppsProc.running = false;
        loadAppsProc.running = true;
        searchField.forceActiveFocus();
    }

    implicitWidth: preferredContentWidth
    implicitHeight: searchBarHeight + layoutSpacing + visibleListHeight
    width: parent && parent.width > 0 ? parent.width : implicitWidth
    height: parent && parent.height > 0 ? parent.height : implicitHeight
    Component.onCompleted: {
        resetLauncher();
    }

    Process {
        id: loadAppsProc

        command: ["python3", Quickshell.shellDir + "/Modules/Launcher/scripts/get_apps.py"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    let parsed = JSON.parse(appFetcherOutput.text);
                    AppState.launcherApps = parsed;
                    root.allApps = parsed;
                    filterApps(searchField.text);
                } catch (e) {
                    console.error("Error parsing apps JSON: " + e);
                }
            }
        }

        stdout: StdioCollector {
            id: appFetcherOutput
        }

    }

    ColumnLayout {
        anchors.fill: parent
        spacing: root.layoutSpacing

        Item {
            id: topSearchContainer

            Layout.fillWidth: true
            Layout.preferredHeight: SettingsService.barConvexMode ? 0 : Constants.size4Xl
            visible: !SettingsService.barConvexMode
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: root.visibleListHeight
            clip: true

            GhostEmptyState {
                width: Math.min(implicitWidth, Math.max(0, parent.width - 2 * Constants.sizeSm))
                anchors.centerIn: parent
                visible: opacity > 0.001
                opacity: (!root.calculation && root.filteredApps.length === 0 && root.isSearching) ? 1 : 0
                text: "Приложения не найдены. Попробуй другое название."

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Rectangle {
                id: resultRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: root.itemHeight
                visible: root.calculation !== null
                color: Theme.bgSecondary
                radius: Constants.sizeLg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Constants.sizeSm
                    anchors.rightMargin: Constants.sizeSm
                    spacing: Constants.sizeSm

                    ThemedText {
                        text: "="
                        color: Theme.accent
                        font.bold: true
                    }

                    ThemedText {
                        Layout.fillWidth: true
                        text: root.calculation ? (root.calculation.error || root.calculation.value) : ""
                        color: root.calculation && root.calculation.error ? Theme.muted : Theme.fg
                        elide: Text.ElideRight
                    }

                    ThemedText {
                        visible: root.calculation !== null && !root.calculation.error
                        text: root.resultCopied ? "Скопировано" : "Enter — копировать"
                        color: Theme.muted
                        customSize: 11
                    }
                }

                TapHandler {
                    enabled: root.calculation !== null && !root.calculation.error
                    onTapped: root.copyResult()
                }
            }

            ListView {
                id: appsView

                property int expandedIndex: -1

                onExpandedIndexChanged: {
                    if (expandedIndex >= 0)
                        Qt.callLater(function() {
                        appsView.positionViewAtIndex(expandedIndex, ListView.Contain);
                    });

                }
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.filteredApps
                spacing: root.listSpacing
                currentIndex: -1
                highlightResizeDuration: 0
                highlightMoveDuration: Constants.animFast
                highlightFollowsCurrentItem: true
                visible: !root.calculation && root.filteredApps.length > 0
                Keys.onPressed: function(event) {
                    root.handleKeyPress(event, false);
                }

                highlight: Item {
                    width: appsView.width
                    height: 44
                    z: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: Constants.sizeLg
                        color: Theme.bgSecondary
                    }

                }

                add: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: root.isSearching ? 0 : Constants.animFast
                        easing.type: Easing.OutQuint
                    }

                }

                populate: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: root.isSearching ? 0 : Constants.animFast
                        easing.type: Easing.OutQuint
                    }

                }

                delegate: LauncherItemDelegate {
                    modelData: model.modelData
                    isCurrent: appsView.currentIndex === index
                    isExpanded: appsView.expandedIndex === index
                    onToggleExpanded: {
                        if (appsView.expandedIndex === index) {
                            appsView.expandedIndex = -1;
                        } else {
                            appsView.expandedIndex = index;
                            appsView.currentIndex = index;
                        }
                    }
                    onLaunchRequested: function(execCmd, terminalFlag) {
                        root.launchApp(execCmd, terminalFlag);
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOff
                    active: true
                }

            }

        }

        Item {
            id: bottomSearchContainer

            Layout.fillWidth: true
            Layout.preferredHeight: SettingsService.barConvexMode ? 40 : 0
            visible: SettingsService.barConvexMode
        }

    }

    ThemedSearchBar {
        id: searchField

        parent: SettingsService.barConvexMode ? bottomSearchContainer : topSearchContainer
        anchors.fill: parent
        preferredHeight: Constants.size4Xl
        placeholderText: "Поиск приложений или выражение…"
        onSearchRequested: (text) => {
            return root.filterApps(text);
        }
        customSize: Constants.sizeMd
        textField.Keys.onPressed: function(event) {
            root.handleKeyPress(event, true);
        }
    }

    Process {
        id: appLauncher
    }

    Process {
        id: copyProcess

        onExited: code => {
            if (code === 0 && root.calculation && command[2] === root.calculation.value)
                root.resultCopied = true;
        }
    }

}
