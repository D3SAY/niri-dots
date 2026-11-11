import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

// Every bind from niri's config.kdl with what it does, through Scripts/system/niri_binds.py:
// click the keys to change them, the switch comments a bind out (and back), the bin removes it,
// "Добавить" makes a new one that opens an app, the folder moves it to another category (or a new
// one). Keys used twice get a "!" that jumps to the twin.
Item {
    id: root

    readonly property string script: Quickshell.shellDir + "/Scripts/system/niri_binds.py"
    property var binds: []
    property string query: ""
    property int editingLine: -1
    property int movingLine: -1
    property var sections: []
    property int highlightLine: -1
    property int confirmDeleteLine: -1
    property bool adding: false
    property string message: ""
    property bool messageIsError: false
    // the bind to show once the list is reloaded after an edit
    property int pendingHighlight: -1
    property var apps: []
    property string appQuery: ""
    readonly property var keyNames: ({
        "Mod": "Super",
        "Return": "Enter",
        "Left": "←",
        "Right": "→",
        "Up": "↑",
        "Down": "↓",
        "Slash": "/",
        "Comma": ",",
        "Period": ".",
        "Minus": "-",
        "Equal": "=",
        "BracketLeft": "[",
        "BracketRight": "]",
        "Escape": "Esc",
        "Print": "PrtSc",
        "Page_Up": "PgUp",
        "Page_Down": "PgDn",
        "WheelScrollDown": "Колесо ↓",
        "WheelScrollUp": "Колесо ↑",
        "XF86AudioRaiseVolume": "Громче",
        "XF86AudioLowerVolume": "Тише",
        "XF86AudioMute": "Без звука",
        "XF86AudioMicMute": "Микрофон",
        "XF86MonBrightnessUp": "Ярче",
        "XF86MonBrightnessDown": "Темнее",
        "XF86AudioPlay": "Play/Pause",
        "XF86AudioNext": "Следующий",
        "XF86AudioPrev": "Предыдущий"
    })
    // normalized keys -> lines of every bind (on or off) using them
    readonly property var keyUsers: {
        let map = {
        };
        for (const b of binds) {
            const k = normKey(b.key);
            (map[k] = map[k] || []).push(b.line);
        }
        return map;
    }
    readonly property var shown: {
        const q = query.trim().toLowerCase();
        if (q === "")
            return binds;

        return binds.filter((b) => {
            return b.key.toLowerCase().includes(q) || b.desc.toLowerCase().includes(q) || b.body.toLowerCase().includes(q) || b.section.toLowerCase().includes(q) || keyLabel(b.key).toLowerCase().includes(q);
        });
    }
    readonly property var shownApps: {
        const q = appQuery.trim().toLowerCase();
        return apps.filter((a) => {
            return q === "" || a.name.toLowerCase().includes(q) || (a.exec || "").toLowerCase().includes(q);
        }).slice(0, 6);
    }

    function normKey(key) {
        const alias = {
            "super": "mod",
            "win": "mod",
            "control": "ctrl",
            "iso_level3_shift": "mod5"
        };
        const parts = key.split("+");
        const mods = parts.slice(0, -1).map((p) => {
            const l = p.toLowerCase();
            return alias[l] || l;
        }).sort();
        return mods.concat([parts[parts.length - 1].toLowerCase()]).join("+");
    }

    function keyLabel(key) {
        return key.split("+").map((p) => {
            return keyNames[p] || p;
        }).join(" + ");
    }

    function twins(bind) {
        return (keyUsers[normKey(bind.key)] || []).filter((l) => {
            return l !== bind.line;
        });
    }

    function reload() {
        listProc.running = true;
    }

    function run(args, okText) {
        if (actionProc.running)
            return ;

        actionProc.okText = okText;
        actionProc.command = ["python3", script].concat(args);
        actionProc.running = true;
    }

    // a new model sends the list back to the top; put it back on the same bind, same offset
    function keepScroll(update) {
        const top = list.indexAt(list.width / 2, list.contentY + 1);
        const item = top >= 0 ? list.itemAtIndex(top) : null;
        const offset = item ? list.contentY - item.y : 0;
        update();
        if (top < 0)
            return ;

        list.positionViewAtIndex(Math.min(top, list.count - 1), ListView.Beginning);
        list.contentY += offset;
    }

    function showMessage(text, isError) {
        message = text;
        messageIsError = isError;
        messageTimer.restart();
    }

    // scroll to a bind and make it blink for a moment
    function highlight(line) {
        if (query !== "" && !shown.some((b) => {
            return b.line === line;
        }))
            searchField.text = "";

        Qt.callLater(() => {
            const i = shown.findIndex((b) => {
                return b.line === line;
            });
            if (i === -1)
                return ;

            list.positionViewAtIndex(i, ListView.Center);
            highlightLine = line;
            highlightTimer.restart();
        });
    }

    function appCommand(exec) {
        return (exec || "").split(" ").filter((a) => {
            return a !== "" && !a.startsWith("%");
        }).map((a) => {
            return a.replace(/^"|"$/g, "");
        });
    }

    function startAdding() {
        adding = true;
        editingLine = -1;
        appQuery = "";
        newTitle.text = "";
        newCommand.text = "";
        newKey.value = "";
        newKey.load("");
        if (apps.length === 0)
            appsProc.running = true;

        Qt.callLater(newKey.start);
    }

    function saveNew() {
        if (newKey.combo === "")
            return showMessage("Выберите комбинацию клавиш", true);

        const cmd = newCommand.text.trim();
        if (cmd === "")
            return showMessage("Выберите приложение или впишите команду", true);

        // a picked app runs as is, a typed command goes through the shell
        const args = newCommand.fromApp ? appCommand(cmd) : ["sh", "-c", cmd];
        const title = newTitle.text.trim() !== "" ? newTitle.text.trim() : cmd;
        run(["add", newKey.combo, title].concat(args), "Комбинация добавлена");
        adding = false;
    }

    Component.onCompleted: reload()

    Process {
        id: listProc

        command: ["python3", root.script, "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    if (r.ok)
                        root.keepScroll(() => {
                        root.binds = r.binds;
                        root.sections = r.sections || [];
                    });

                } catch (e) {
                    root.showMessage("Не удалось прочитать config.kdl", true);
                }
                if (root.pendingHighlight !== -1) {
                    root.highlight(root.pendingHighlight);
                    root.pendingHighlight = -1;
                }
            }
        }

    }

    Process {
        id: actionProc

        property string okText: ""

        stdout: StdioCollector {
            onStreamFinished: {
                let r = {
                    "ok": false,
                    "error": "Нет ответа от niri_binds.py"
                };
                try {
                    r = JSON.parse(text);
                } catch (e) {
                }
                if (r.ok && r.conflict)
                    root.showMessage("Эта комбинация уже занята — сохранено, но выключено. Измените одну из двух или выключите другую", true);
                else if (r.ok)
                    root.showMessage(actionProc.okText, false);
                else
                    root.showMessage(r.error || "Ошибка", true);
                if (r.conflict)
                    root.pendingHighlight = r.conflict;
                else if (r.line)
                    root.pendingHighlight = r.line;

                root.reload();
            }
        }

    }

    Process {
        id: appsProc

        command: ["python3", Quickshell.shellDir + "/Modules/Launcher/scripts/get_apps.py"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apps = JSON.parse(text).sort((a, b) => {
                        return a.name.localeCompare(b.name);
                    });
                } catch (e) {
                }
            }
        }

    }

    Timer {
        id: messageTimer

        interval: 6000
        onTriggered: root.message = ""
    }

    Timer {
        id: highlightTimer

        interval: 2500
        onTriggered: root.highlightLine = -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        spacing: Constants.sizeMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            ThemedTextField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: "Поиск: клавиша или действие…"
                showSubmitHint: false
                onTextChanged: root.query = text
            }

            Rectangle {
                implicitWidth: addRow.implicitWidth + Constants.sizeLg * 2
                implicitHeight: 34
                radius: Constants.sizeXs
                color: addArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent

                RowLayout {
                    id: addRow

                    anchors.centerIn: parent
                    spacing: Constants.sizeXs

                    SvgIcon {
                        icon: "plus"
                        iconSize: Constants.sizeMd
                        iconColor: Theme.bg
                        flat: true
                    }

                    ThemedText {
                        text: "Добавить"
                        customSize: Constants.sizeSm
                        font.bold: true
                        color: Theme.bg
                    }

                }

                MouseArea {
                    id: addArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adding ? (root.adding = false) : root.startAdding()
                }

            }

        }

        ThemedText {
            Layout.fillWidth: true
            visible: root.message !== ""
            text: root.message
            wrapMode: Text.Wrap
            customSize: Constants.sizeSm
            color: root.messageIsError ? Theme.accentComplementary : Theme.accent
        }

        // new bind that opens an app
        Rectangle {
            Layout.fillWidth: true
            visible: root.adding
            implicitHeight: addColumn.implicitHeight + Constants.sizeLg * 2
            radius: Constants.sizeSm
            color: Theme.bgTertiary
            border.width: 1
            border.color: Theme.accent

            ColumnLayout {
                id: addColumn

                anchors.fill: parent
                anchors.margins: Constants.sizeLg
                spacing: Constants.sizeSm

                ThemedText {
                    text: "Новая комбинация"
                    customSize: Constants.sizeMd
                    font.bold: true
                }

                KeyEditor {
                    id: newKey

                    showButtons: false
                }

                ThemedTextField {
                    id: appSearch

                    label: "Приложение"
                    placeholderText: "Найти приложение…"
                    showSubmitHint: false
                    onTextChanged: root.appQuery = text
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Constants.sizeXs

                    Repeater {
                        model: root.shownApps

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool picked: newCommand.fromApp && newCommand.text === modelData.exec

                            implicitWidth: appRow.implicitWidth + Constants.sizeMd * 2
                            implicitHeight: 32
                            radius: Constants.sizeXs
                            color: picked ? Theme.bgAccent : (appArea.containsMouse ? Theme.bgSecondary : Theme.bg)
                            border.width: 1
                            border.color: picked ? Theme.accent : Theme.border

                            RowLayout {
                                id: appRow

                                anchors.centerIn: parent
                                spacing: Constants.sizeXs

                                Image {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    sourceSize: Qt.size(18, 18)
                                    source: parent.parent.modelData.icon ? (Quickshell.iconPath(parent.parent.modelData.icon, true) || "") : ""
                                    visible: source != ""
                                }

                                ThemedText {
                                    text: parent.parent.modelData.name
                                    customSize: Constants.sizeSm
                                }

                            }

                            MouseArea {
                                id: appArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    newCommand.text = parent.modelData.exec;
                                    newCommand.fromApp = true;
                                    newTitle.text = parent.modelData.name;
                                }
                            }

                        }

                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeSm

                    ThemedTextField {
                        id: newCommand

                        // true while the text is an app's Exec line picked above
                        property bool fromApp: false

                        label: "Команда"
                        placeholderText: "или впишите свою, например ghostty -e btop"
                        showSubmitHint: false

                        Connections {
                            function onTextEdited() {
                                newCommand.fromApp = false;
                            }

                            target: newCommand.textField
                        }

                    }

                    ThemedTextField {
                        id: newTitle

                        Layout.preferredWidth: 220
                        Layout.fillWidth: false
                        label: "Название"
                        placeholderText: "например Калькулятор"
                        showSubmitHint: false
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeSm

                    ThemedText {
                        Layout.fillWidth: true
                        text: newKey.combo !== "" && root.keyUsers[root.normKey(newKey.combo)] ? "⚠ Эта комбинация уже используется — новая будет сохранена выключенной" : ""
                        color: Theme.accentComplementary
                        customSize: Constants.sizeXs + 2
                        wrapMode: Text.Wrap
                    }

                    SvgIconButton {
                        icon: "x"
                        iconSize: Constants.sizeMd
                        iconColor: Theme.muted
                        flat: true
                        onClicked: root.adding = false
                    }

                    SvgIconButton {
                        icon: "check"
                        iconSize: Constants.sizeMd
                        iconColor: Theme.accent
                        onClicked: root.saveNew()
                    }

                }

            }

        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Constants.size2Xs
            model: root.shown
            boundsBehavior: Flickable.StopAtBounds

            // a section title above the first bind of each section
            delegate: Column {
                id: cell

                required property var modelData
                required property int index
                readonly property bool firstOfSection: index === 0 || root.shown[index - 1].section !== modelData.section

                width: list.width

                ThemedText {
                    visible: cell.firstOfSection
                    width: parent.width
                    topPadding: cell.index === 0 ? 0 : Constants.sizeLg
                    bottomPadding: Constants.sizeXs
                    text: cell.modelData.section.toUpperCase()
                    customSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    color: Theme.muted
                }

            Rectangle {
                id: row

                readonly property var bind: cell.modelData
                readonly property var twinLines: root.twins(bind)
                readonly property bool editing: root.editingLine === bind.line
                readonly property bool moving: root.movingLine === bind.line
                readonly property bool highlighted: root.highlightLine === bind.line

                width: list.width
                implicitHeight: editing ? editor.implicitHeight + Constants.sizeMd * 2 : (moving ? mover.implicitHeight + Constants.sizeMd * 2 : Math.max(52, info.implicitHeight + Constants.sizeSm * 2))
                radius: Constants.sizeSm
                color: highlighted ? Theme.bgAccent : (rowHover.hovered ? Theme.bgSecondary : Theme.bgTertiary)
                border.width: highlighted || editing || moving ? 2 : 0
                border.color: Theme.accent

                HoverHandler {
                    id: rowHover
                }

                KeyEditor {
                    id: editor

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Constants.sizeMd
                    visible: row.editing
                    value: row.bind.key
                    onAccepted: (combo) => {
                        root.editingLine = -1;
                        if (combo !== row.bind.key)
                            root.run(["set-key", String(row.bind.line), row.bind.key, combo], "Комбинация изменена");

                    }
                    onCancelled: root.editingLine = -1
                }

                // choosing another category
                ColumnLayout {
                    id: mover

                    function moveTo(name) {
                        root.movingLine = -1;
                        if (name.trim() !== "" && name !== row.bind.section)
                            root.run(["move", String(row.bind.line), row.bind.key, name.trim()], "Перенесено в «" + name.trim() + "»");

                    }

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Constants.sizeMd
                    visible: row.moving
                    spacing: Constants.sizeSm

                    RowLayout {
                        Layout.fillWidth: true

                        ThemedText {
                            Layout.fillWidth: true
                            text: "Категория для «" + row.bind.desc + "»"
                            customSize: Constants.sizeSm
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        SvgIconButton {
                            icon: "x"
                            iconSize: Constants.sizeMd
                            iconColor: Theme.muted
                            flat: true
                            padding: Constants.sizeXs
                            onClicked: root.movingLine = -1
                        }

                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Constants.sizeXs

                        Repeater {
                            model: row.moving ? root.sections : []

                            delegate: Rectangle {
                                required property string modelData
                                readonly property bool current: modelData === row.bind.section

                                implicitWidth: secLabel.implicitWidth + Constants.sizeMd * 2
                                implicitHeight: 30
                                radius: Constants.sizeXs
                                color: current ? Theme.bgAccent : (secArea.containsMouse ? Theme.bgSecondary : Theme.bg)
                                border.width: 1
                                border.color: current ? Theme.accent : Theme.border

                                ThemedText {
                                    id: secLabel

                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    customSize: Constants.sizeSm
                                    color: parent.current ? Theme.accent : Theme.fg
                                }

                                MouseArea {
                                    id: secArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: parent.current ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    onClicked: mover.moveTo(parent.modelData)
                                }

                            }

                        }

                    }

                    ThemedTextField {
                        id: newSection

                        placeholderText: "Новая категория: название и Enter"
                        customSize: Constants.sizeSm
                        onEditingFinished: {
                            if (row.moving && text.trim() !== "")
                                mover.moveTo(text);

                            text = "";
                        }
                    }

                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Constants.sizeMd
                    anchors.rightMargin: Constants.sizeSm
                    spacing: Constants.sizeMd
                    visible: !row.editing && !row.moving
                    opacity: row.bind.enabled ? 1 : 0.45

                    // the keys; click to change them
                    Rectangle {
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 34
                        radius: Constants.sizeXs
                        color: keyArea.containsMouse ? Theme.bg : "transparent"
                        border.width: keyArea.containsMouse ? 1 : 0
                        border.color: Theme.border

                        Flow {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Constants.size2Xs
                            spacing: Constants.size2Xs

                            Repeater {
                                model: row.bind.key.split("+")

                                delegate: Rectangle {
                                    required property string modelData

                                    implicitWidth: Math.max(implicitHeight, chip.implicitWidth + Constants.sizeSm * 2)
                                    implicitHeight: 24
                                    radius: Constants.size2Xs + 2
                                    color: Theme.bgSecondary
                                    border.width: 1
                                    border.color: Theme.border

                                    ThemedText {
                                        id: chip

                                        anchors.centerIn: parent
                                        text: root.keyNames[parent.modelData] || parent.modelData
                                        customSize: Constants.sizeXs + 2
                                        font.bold: true
                                    }

                                }

                            }

                        }

                        MouseArea {
                            id: keyArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.adding = false;
                                root.movingLine = -1;
                                root.editingLine = row.bind.line;
                                Qt.callLater(editor.start);
                            }
                        }

                    }

                    ColumnLayout {
                        id: info

                        Layout.fillWidth: true
                        spacing: 0

                        ThemedText {
                            Layout.fillWidth: true
                            text: row.bind.desc + (row.bind.enabled ? "" : "  · выключено")
                            customSize: Constants.sizeSm
                            font.weight: Font.DemiBold
                            wrapMode: Text.Wrap
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: row.bind.body
                            customSize: Constants.sizeXs + 1
                            color: Theme.muted
                            elide: Text.ElideRight
                            font.family: "CaskaydiaCove Nerd Font Mono"
                        }

                    }

                    SvgIconButton {
                        icon: "folder"
                        iconSize: Constants.sizeMd
                        iconColor: Theme.muted
                        flat: true
                        padding: Constants.sizeXs
                        onClicked: {
                            root.adding = false;
                            root.editingLine = -1;
                            root.movingLine = row.bind.line;
                        }

                        ThemedTooltip {
                            visible: parent.hovered
                            text: "Сменить категорию"
                        }

                    }

                    // the same keys are used by another bind: jump to it
                    Rectangle {
                        visible: row.twinLines.length > 0
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: width / 2
                        color: twinArea.containsMouse ? Theme.accentComplementary : Qt.rgba(Theme.accentComplementary.r, Theme.accentComplementary.g, Theme.accentComplementary.b, 0.2)

                        ThemedText {
                            anchors.centerIn: parent
                            text: "!"
                            font.bold: true
                            customSize: Constants.sizeMd
                            color: twinArea.containsMouse ? Theme.bg : Theme.accentComplementary
                        }

                        MouseArea {
                            id: twinArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.highlight(row.twinLines[0])
                        }

                        ThemedTooltip {
                            visible: twinArea.containsMouse
                            text: "Эта комбинация используется ещё раз — показать"
                        }

                    }

                    Switch {
                        id: onSwitch

                        Layout.alignment: Qt.AlignVCenter
                        checked: row.bind.enabled
                        implicitWidth: Constants.size4Xl
                        implicitHeight: Constants.sizeXl + 2
                        onToggled: {
                            checked = Qt.binding(() => {
                                return row.bind.enabled;
                            });
                            root.run(["toggle", String(row.bind.line), row.bind.key], row.bind.enabled ? "Комбинация выключена (закомментирована)" : "Комбинация снова работает");
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }

                        indicator: Rectangle {
                            implicitWidth: Constants.size4Xl
                            implicitHeight: Constants.sizeXl + 2
                            radius: height / 2
                            color: onSwitch.checked ? Theme.accent : Theme.bgSecondary
                            border.width: 1
                            border.color: onSwitch.checked ? Theme.accent : Theme.border

                            Rectangle {
                                x: onSwitch.checked ? parent.width - width - 3 : 3
                                y: (parent.height - height) / 2
                                width: Constants.sizeLg
                                height: Constants.sizeLg
                                radius: width / 2
                                color: onSwitch.checked ? Theme.white : Theme.muted

                                Behavior on x {
                                    NumberAnimation {
                                        duration: Constants.animFast
                                    }

                                }

                            }

                        }

                    }

                    // first click arms, second deletes
                    SvgIconButton {
                        readonly property bool armed: root.confirmDeleteLine === row.bind.line

                        icon: "trash"
                        iconSize: Constants.sizeMd
                        iconColor: armed ? Theme.bg : Theme.muted
                        bgColor: armed ? Theme.accentComplementary : "transparent"
                        flat: !armed
                        padding: Constants.sizeXs
                        onClicked: {
                            if (armed) {
                                root.confirmDeleteLine = -1;
                                root.run(["delete", String(row.bind.line), row.bind.key], "Комбинация удалена");
                            } else {
                                root.confirmDeleteLine = row.bind.line;
                                confirmTimer.restart();
                                root.showMessage("Нажмите на корзину ещё раз, чтобы удалить «" + row.bind.desc + "»", true);
                            }
                        }
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animNormal
                    }

                }

            }

            }

            ScrollIndicator.vertical: ScrollIndicator {
            }

        }

    }

    Timer {
        id: confirmTimer

        interval: 4000
        onTriggered: root.confirmDeleteLine = -1
    }

}
