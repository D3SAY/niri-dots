import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

// Picks keys for a bind: modifier buttons plus one key, caught from the keyboard by its physical
// position (so the Russian layout gives the same names as English). niri itself grabs its own
// shortcuts before this window sees them, which is why modifiers are buttons; mouse-wheel binds
// and the like can be typed into the text field.
FocusScope {
    id: root

    property string value: ""
    property bool showButtons: true
    property bool hasMod: false
    property bool hasCtrl: false
    property bool hasShift: false
    property bool hasAlt: false
    property string key: ""
    readonly property string combo: {
        if (key === "")
            return "";

        let parts = [];
        if (hasMod)
            parts.push("Mod");

        if (hasCtrl)
            parts.push("Ctrl");

        if (hasShift)
            parts.push("Shift");

        if (hasAlt)
            parts.push("Alt");

        parts.push(key);
        return parts.join("+");
    }
    // evdev key codes -> xkb key names for niri (US positions)
    readonly property var scanNames: ({
        "1": "Escape",
        "2": "1",
        "3": "2",
        "4": "3",
        "5": "4",
        "6": "5",
        "7": "6",
        "8": "7",
        "9": "8",
        "10": "9",
        "11": "0",
        "12": "Minus",
        "13": "Equal",
        "14": "BackSpace",
        "15": "Tab",
        "16": "Q",
        "17": "W",
        "18": "E",
        "19": "R",
        "20": "T",
        "21": "Y",
        "22": "U",
        "23": "I",
        "24": "O",
        "25": "P",
        "26": "BracketLeft",
        "27": "BracketRight",
        "28": "Return",
        "30": "A",
        "31": "S",
        "32": "D",
        "33": "F",
        "34": "G",
        "35": "H",
        "36": "J",
        "37": "K",
        "38": "L",
        "39": "Semicolon",
        "40": "Apostrophe",
        "41": "Grave",
        "43": "Backslash",
        "44": "Z",
        "45": "X",
        "46": "C",
        "47": "V",
        "48": "B",
        "49": "N",
        "50": "M",
        "51": "Comma",
        "52": "Period",
        "53": "Slash",
        "57": "Space",
        "59": "F1",
        "60": "F2",
        "61": "F3",
        "62": "F4",
        "63": "F5",
        "64": "F6",
        "65": "F7",
        "66": "F8",
        "67": "F9",
        "68": "F10",
        "87": "F11",
        "88": "F12",
        "99": "Print",
        "102": "Home",
        "103": "Up",
        "104": "Page_Up",
        "105": "Left",
        "106": "Right",
        "107": "End",
        "108": "Down",
        "109": "Page_Down",
        "110": "Insert",
        "111": "Delete",
        "113": "XF86AudioMute",
        "114": "XF86AudioLowerVolume",
        "115": "XF86AudioRaiseVolume",
        "119": "Pause",
        "163": "XF86AudioNext",
        "164": "XF86AudioPlay",
        "165": "XF86AudioPrev"
    })

    signal accepted(string combo)
    signal cancelled()

    function load(text) {
        let parts = (text || "").split("+").filter((p) => {
            return p !== "";
        });
        let mods = parts.slice(0, -1).map((p) => {
            return p.toLowerCase();
        });
        hasMod = mods.indexOf("mod") !== -1 || mods.indexOf("super") !== -1 || mods.indexOf("win") !== -1;
        hasCtrl = mods.indexOf("ctrl") !== -1 || mods.indexOf("control") !== -1;
        hasShift = mods.indexOf("shift") !== -1;
        hasAlt = mods.indexOf("alt") !== -1;
        key = parts.length > 0 ? parts[parts.length - 1] : "";
    }

    function start() {
        load(value);
        catcher.forceActiveFocus();
    }

    implicitHeight: column.implicitHeight
    Layout.fillWidth: true
    Component.onCompleted: load(value)
    onValueChanged: load(value)
    onComboChanged: manual.text = combo

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Constants.sizeSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            Repeater {
                model: [{
                    "label": "Super",
                    "prop": "hasMod"
                }, {
                    "label": "Ctrl",
                    "prop": "hasCtrl"
                }, {
                    "label": "Shift",
                    "prop": "hasShift"
                }, {
                    "label": "Alt",
                    "prop": "hasAlt"
                }]

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: root[modelData.prop]

                    implicitWidth: modLabel.implicitWidth + Constants.sizeLg
                    implicitHeight: 32
                    radius: Constants.sizeXs
                    color: on ? Theme.accent : (modArea.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
                    border.width: 1
                    border.color: on ? Theme.accent : Theme.border

                    ThemedText {
                        id: modLabel

                        anchors.centerIn: parent
                        text: parent.modelData.label
                        customSize: Constants.sizeSm
                        font.bold: true
                        color: parent.on ? Theme.bg : Theme.fg
                    }

                    MouseArea {
                        id: modArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root[parent.modelData.prop] = !parent.on;
                            catcher.forceActiveFocus();
                        }
                    }

                }

            }

            ThemedText {
                text: "+"
                color: Theme.muted
                customSize: Constants.sizeMd
            }

            // the main key: click it and press a key
            Rectangle {
                id: catcher

                Layout.preferredWidth: 170
                implicitHeight: 32
                radius: Constants.sizeXs
                color: Theme.bgSecondary
                border.width: activeFocus ? 2 : 1
                border.color: activeFocus ? Theme.accent : Theme.border
                activeFocusOnTab: true
                Keys.onPressed: (event) => {
                    if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr].indexOf(event.key) !== -1)
                        return ;

                    event.accepted = true;
                    // Esc cancels; Escape as the bind's key can be typed by hand
                    if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                        root.cancelled();
                        return ;
                    }
                    let name = root.scanNames[String(event.nativeScanCode - 8)];
                    if (!name && event.text && event.text.trim() !== "")
                        name = event.text.toUpperCase();

                    if (!name)
                        return ;

                    // modifiers niri let through count too
                    if (event.modifiers & Qt.ControlModifier)
                        root.hasCtrl = true;

                    if (event.modifiers & Qt.ShiftModifier)
                        root.hasShift = true;

                    if (event.modifiers & Qt.AltModifier)
                        root.hasAlt = true;

                    if (event.modifiers & Qt.MetaModifier)
                        root.hasMod = true;

                    root.key = name;
                }

                ThemedText {
                    anchors.centerIn: parent
                    text: root.key !== "" ? root.key : (catcher.activeFocus ? "Нажмите клавишу…" : "Клавиша")
                    customSize: Constants.sizeSm
                    font.bold: root.key !== ""
                    color: root.key !== "" ? Theme.fg : Theme.muted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: catcher.forceActiveFocus()
                }

            }

            Item {
                Layout.fillWidth: true
            }

            SvgIconButton {
                visible: root.showButtons
                icon: "check"
                iconSize: Constants.sizeMd
                iconColor: root.combo !== "" ? Theme.accent : Theme.muted
                flat: true
                padding: Constants.sizeXs
                disabled: root.combo === ""
                onClicked: root.accepted(root.combo)
            }

            SvgIconButton {
                visible: root.showButtons
                icon: "x"
                iconSize: Constants.sizeMd
                iconColor: Theme.muted
                flat: true
                padding: Constants.sizeXs
                onClicked: root.cancelled()
            }

        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            ThemedText {
                text: "Вручную:"
                customSize: Constants.sizeXs + 2
                color: Theme.muted
            }

            ThemedTextField {
                id: manual

                Layout.fillWidth: true
                customSize: Constants.sizeXs + 2
                placeholderText: "например Mod+Shift+WheelScrollDown"
                onEditingFinished: root.load(text.trim())
            }

        }

    }

}
