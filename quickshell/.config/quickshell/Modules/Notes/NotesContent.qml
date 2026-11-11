import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Scratchpad drawer after Whisp (github.com/tanaybhomia/Whisp, GPL-3.0): no titles, files or
// save button, just a row of notes to flip through. Typing saves on its own, an emptied note
// disappears when you leave it, flipping past the last note gives a blank one.
// Keys: Ctrl+N new, Ctrl+D delete, Ctrl+P pin, Ctrl+E preview, Alt+←/→ flip, Esc close.
FocusScope {
    id: root

    readonly property string storePath: Quickshell.env("HOME") + "/.local/share/minflair/notes.json"
    readonly property string monoFont: "CaskaydiaCove Nerd Font Mono"
    property var notes: []
    property int currentIndex: 0
    property bool previewMode: false
    property bool loaded: false
    // set while the editor text is replaced from code, so it isn't taken for typing
    property bool _switching: false
    readonly property var current: notes.length > 0 ? notes[Math.min(currentIndex, notes.length - 1)] : null

    signal closeRequested()

    function newId() {
        return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    }

    function blankNote() {
        let now = Date.now();
        return {
            "id": newId(),
            "text": "",
            "pinned": false,
            "created": now,
            "updated": now
        };
    }

    // pinned notes first, the rest in the order they were made
    function sorted(list) {
        return list.slice().sort((a, b) => {
            if (a.pinned !== b.pinned)
                return a.pinned ? -1 : 1;

            return a.created - b.created;
        });
    }

    function showNote(index, direction) {
        root._switching = true;
        root.currentIndex = Math.max(0, Math.min(index, root.notes.length - 1));
        editor.text = root.current ? root.current.text : "";
        editor.cursorPosition = editor.length;
        root._switching = false;
        if (direction !== 0) {
            slideAnim.from = direction * Constants.size3Xl;
            slideAnim.restart();
        }
    }

    // drop the note being left if it was emptied, unless it's the only one or pinned
    function dropIfEmpty(index) {
        let n = root.notes[index];
        if (!n || n.pinned || n.text.trim() !== "" || root.notes.length < 2)
            return false;

        let next = root.notes.slice();
        next.splice(index, 1);
        root.notes = next;
        return true;
    }

    function flip(step) {
        let target = root.currentIndex + step;
        if (target >= root.notes.length) {
            // past the last note: a blank slate, unless this one is blank already
            if (!root.current || root.current.text.trim() === "")
                return ;

            root.notes = root.notes.concat([root.blankNote()]);
        } else if (target < 0) {
            return ;
        }
        if (root.dropIfEmpty(root.currentIndex) && step > 0)
            target -= 1;

        root.showNote(target, step);
        root.save();
    }

    function createNote() {
        let from = root.currentIndex;
        let next = root.notes.concat([root.blankNote()]);
        root.notes = next;
        if (root.dropIfEmpty(from))
            next = root.notes;

        root.showNote(next.length - 1, 1);
        root.previewMode = false;
        root.save();
    }

    function deleteNote() {
        if (!root.current)
            return ;

        let next = root.notes.slice();
        next.splice(root.currentIndex, 1);
        if (next.length === 0)
            next.push(root.blankNote());

        root.notes = next;
        root.showNote(Math.min(root.currentIndex, next.length - 1), -1);
        root.save();
    }

    function togglePin() {
        if (!root.current)
            return ;

        let id = root.current.id;
        root.current.pinned = !root.current.pinned;
        root.notes = root.sorted(root.notes);
        root.showNote(root.notes.findIndex((n) => {
            return n.id === id;
        }), 0);
        root.save();
    }

    function save() {
        if (!root.loaded)
            return ;

        saveTimer.stop();
        dirProc.running = true;
    }

    function focusEditor() {
        if (root.previewMode)
            root.forceActiveFocus();
        else
            editor.forceActiveFocus();
    }

    function relativeTime(ms) {
        let s = Math.round((Date.now() - ms) / 1000);
        if (s < 60)
            return "только что";

        if (s < 3600)
            return Math.floor(s / 60) + " мин назад";

        if (s < 86400)
            return Math.floor(s / 3600) + " ч назад";

        return new Date(ms).toLocaleDateString(Constants.locale, "d MMM");
    }

    implicitWidth: 440
    implicitHeight: 560
    Keys.onPressed: (event) => {
        let ctrl = event.modifiers & Qt.ControlModifier;
        let alt = event.modifiers & Qt.AltModifier;
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
        } else if (ctrl && event.key === Qt.Key_N) {
            root.createNote();
        } else if (ctrl && event.key === Qt.Key_D) {
            root.deleteNote();
        } else if (ctrl && event.key === Qt.Key_P) {
            root.togglePin();
        } else if (ctrl && event.key === Qt.Key_E) {
            root.previewMode = !root.previewMode;
            root.focusEditor();
        } else if ((alt && event.key === Qt.Key_Right) || (ctrl && event.key === Qt.Key_PageDown)) {
            root.flip(1);
        } else if ((alt && event.key === Qt.Key_Left) || (ctrl && event.key === Qt.Key_PageUp)) {
            root.flip(-1);
        } else {
            return ;
        }
        event.accepted = true;
    }

    FileView {
        id: store

        path: root.storePath
        printErrors: false
        // loaded fires again after our own writes; the notes in memory are newer then
        onLoaded: {
            if (root.loaded)
                return ;

            let list = [];
            try {
                list = JSON.parse(text()).notes || [];
            } catch (e) {
                console.warn("notes: unreadable " + root.storePath + ": " + e);
            }
            root.notes = list.length > 0 ? root.sorted(list) : [root.blankNote()];
            root.loaded = true;
            root.showNote(root.notes.length - 1, 0);
        }
        onLoadFailed: {
            root.notes = [root.blankNote()];
            root.loaded = true;
            root.showNote(0, 0);
        }
    }

    function serialized() {
        return JSON.stringify({
            "notes": root.notes.filter((n) => {
                return n.pinned || n.text.trim() !== "";
            })
        }, null, 1);
    }

    // the Island bar destroys the drawer on close: write what the save timer hasn't yet, right away
    Component.onDestruction: {
        if (root.loaded && saveTimer.running) {
            store.blockWrites = true;
            store.setText(root.serialized());
        }
    }

    // the store's folder may not exist yet; write once it does
    Process {
        id: dirProc

        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/minflair"]
        onExited: store.setText(root.serialized())
    }

    Timer {
        id: saveTimer

        interval: 500
        onTriggered: root.save()
    }

    // relative "edited" time in the header
    Timer {
        id: clockTick

        property int tick: 0

        interval: 30000
        repeat: true
        running: root.visible
        onTriggered: tick++
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.size3Xs

                ThemedText {
                    text: "Заметки"
                    customSize: Constants.sizeLg
                    font.bold: true
                }

                ThemedText {
                    text: {
                        clockTick.tick;
                        if (!root.current)
                            return "";

                        let pos = (root.currentIndex + 1) + " из " + root.notes.length;
                        let edited = root.current.text.trim() === "" ? "пустая" : "изменена " + root.relativeTime(root.current.updated);
                        return pos + "  ·  " + edited;
                    }
                    customSize: Constants.sizeXs + 2
                    color: Theme.muted
                }

            }

            Item {
                Layout.fillWidth: true
            }

            SvgIconButton {
                icon: root.current && root.current.pinned ? "star-filled" : "star"
                isActive: root.current !== null && root.current.pinned
                iconSize: Constants.sizeSm
                iconColor: isActive ? Theme.fg : Theme.accent
                onClicked: root.togglePin()
            }

            SvgIconButton {
                icon: root.previewMode ? "eye-off" : "eye"
                isActive: root.previewMode
                iconSize: Constants.sizeSm
                iconColor: isActive ? Theme.fg : Theme.accent
                onClicked: {
                    root.previewMode = !root.previewMode;
                    root.focusEditor();
                }
            }

            SvgIconButton {
                icon: "trash"
                iconSize: Constants.sizeSm
                iconColor: Theme.accent
                onClicked: root.deleteNote()
            }

            SvgIconButton {
                icon: "plus"
                iconSize: Constants.sizeSm
                iconColor: Theme.accent
                onClicked: root.createNote()
            }

        }

        // the sheet: dotted paper with the editor or its Markdown preview on top
        Rectangle {
            id: sheet

            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Constants.sizeSm
            color: Theme.bgSecondary
            clip: true

            Canvas {
                id: dots

                readonly property color dotColor: Theme.border

                anchors.fill: parent
                onDotColorChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = dotColor;
                    let step = Constants.sizeXl;
                    for (let y = step / 2; y < height; y += step) {
                        for (let x = step / 2; x < width; x += step) {
                            ctx.beginPath();
                            ctx.arc(x, y, 1, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }
                }
            }

            Item {
                id: page

                anchors.fill: parent
                anchors.margins: Constants.sizeSm

                ScrollView {
                    anchors.fill: parent
                    visible: !root.previewMode
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    TextArea {
                        id: editor

                        wrapMode: TextEdit.Wrap
                        font.family: root.monoFont
                        font.pixelSize: Math.round(Constants.sizeMd * SettingsService.fontScale)
                        color: Theme.fg
                        placeholderText: "Начните писать…"
                        placeholderTextColor: Theme.muted
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.fg
                        selectByMouse: true
                        background: null
                        padding: Constants.size2Xs
                        onTextChanged: {
                            if (root._switching || !root.current)
                                return ;

                            root.current.text = text;
                            root.current.updated = Date.now();
                            clockTick.tick++;
                            saveTimer.restart();
                        }
                    }

                }

                ScrollView {
                    anchors.fill: parent
                    visible: root.previewMode
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    TextEdit {
                        width: page.width
                        readOnly: true
                        selectByMouse: true
                        textFormat: TextEdit.MarkdownText
                        text: root.previewMode ? editor.text : ""
                        wrapMode: TextEdit.Wrap
                        font.family: Constants.fontFamily
                        font.pixelSize: Math.round(Constants.sizeMd * SettingsService.fontScale)
                        color: Theme.fg
                        selectionColor: Theme.accent
                        padding: Constants.size2Xs
                        onLinkActivated: (link) => {
                            return Qt.openUrlExternally(link);
                        }
                    }

                }

                transform: Translate {
                    id: slide
                }

                NumberAnimation {
                    id: slideAnim

                    target: slide
                    property: "x"
                    to: 0
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

            // horizontal swipe on the touchpad (or Shift+wheel) flips notes, like Whisp's carousel
            WheelHandler {
                property real acc: 0

                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (event) => {
                    let dx = event.angleDelta.x !== 0 ? event.angleDelta.x : ((event.modifiers & Qt.ShiftModifier) ? event.angleDelta.y : 0);
                    if (dx === 0) {
                        event.accepted = false;
                        return ;
                    }

                    acc += dx;
                    if (Math.abs(acc) >= 240) {
                        root.flip(acc < 0 ? 1 : -1);
                        acc = 0;
                    }
                }
            }

        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            Row {
                spacing: Constants.size2Xs
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: Math.min(root.notes.length, 12)

                    Rectangle {
                        required property int index
                        readonly property bool isCurrent: index === Math.min(root.currentIndex, 11)

                        width: isCurrent ? Constants.sizeLg : Constants.size2Xs + 2
                        height: Constants.size2Xs + 2
                        radius: height / 2
                        color: isCurrent ? Theme.accent : (root.notes[index] && root.notes[index].pinned ? Theme.fg : Theme.muted)

                        Behavior on width {
                            NumberAnimation {
                                duration: Constants.animFast
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

            Item {
                Layout.fillWidth: true
            }

            ThemedText {
                text: "Ctrl+N новая · Ctrl+D удалить · Alt+←/→"
                customSize: Constants.sizeXs + 2
                color: Theme.muted
            }

        }

    }

}
