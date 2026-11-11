//@ pragma UseQApplication
// Login screen in the style of the minflair lock screen. greetd runs it inside a bare niri
// (/etc/greetd/niri-greeter.kdl) as the "greeter" user; after the password it starts niri-session.
// Wallpaper, colors, user name and avatar come from /var/cache/minflair-greeter, which the
// desktop session keeps up to date (Quickshell theme_appliers/greeter.py).
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Wayland

ShellRoot {
    id: shell

    // GREETER_SHARED only for trying the greeter out of a test copy
    readonly property string shared: Quickshell.env("GREETER_SHARED") || "/var/cache/minflair-greeter"
    readonly property string fontFamily: "Geist"
    property var colors: ({})
    readonly property color bg: colors.opaqueBg || colors.bg || "#0b0b0e"
    readonly property color fg: colors.fg || "#eeeeee"
    readonly property color accent: colors.accent || "#8a63f0"
    readonly property color accentAlt: colors.accentComplementary || "#e05cc0"
    readonly property color muted: Qt.rgba(fg.r, fg.g, fg.b, 0.45)
    readonly property color border: Qt.rgba(fg.r, fg.g, fg.b, 0.12)
    readonly property color surface: Qt.rgba(fg.r, fg.g, fg.b, 0.05)
    property string user: ""
    property string hostname: ""
    property string layout: ""
    property bool busy: false
    property string message: ""
    property bool failed: false
    property date now: new Date()
    // the password waits here until greetd asks for it
    property string pending: ""

    // login steps go to the system journal (journalctl -t minflair-greeter); never the password
    function note(text) {
        Quickshell.execDetached(["logger", "-t", "minflair-greeter", text]);
    }

    // the field lives inside the per-screen window, so its text comes in as an argument
    // and clearing it goes out through resetField
    signal resetField()

    function login(password) {
        if (shell.busy || password === "")
            return ;

        if (shell.user === "") {
            shell.note("no user name in " + shell.shared + "/user");
            shell.fail("Не найдено имя пользователя");
            return ;
        }
        shell.note("login as " + shell.user + ", greetd available: " + Greetd.available + ", state: " + Greetd.state);
        shell.busy = true;
        stuck.restart();
        shell.failed = false;
        shell.message = "";
        shell.pending = password;
        if (Greetd.state === GreetdState.Inactive)
            Greetd.createSession(shell.user);
        else
            Greetd.respond(shell.pending);
    }

    function fail(text) {
        stuck.stop();
        shell.busy = false;
        shell.failed = true;
        shell.message = text;
        shell.pending = "";
        shell.resetField();
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();

    }

    Connections {
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            shell.note("greetd asks: " + message + (responseRequired ? " (answering)" : ""));
            if (responseRequired) {
                Greetd.respond(shell.pending);
                shell.pending = "";
            } else if (error) {
                shell.message = message;
            }
        }

        function onAuthFailure(message) {
            shell.note("auth failure: " + message);
            shell.fail("Неверный пароль");
        }

        function onError(error) {
            shell.note("greetd error: " + error);
            shell.fail(error);
        }

        function onReadyToLaunch() {
            shell.note("password accepted, starting niri-session");
            stuck.stop();
            shell.message = "";
            Greetd.launch(["niri-session"], [], true);
        }

        target: Greetd
    }

    FileView {
        path: shell.shared + "/colorscheme.json"
        onLoaded: {
            try {
                shell.colors = JSON.parse(text());
            } catch (e) {
                console.warn("greeter: bad colorscheme.json: " + e);
            }
        }
    }

    FileView {
        path: shell.shared + "/user"
        onLoaded: shell.user = text().trim()
    }

    Process {
        running: true
        command: ["cat", "/etc/hostname"]

        stdout: StdioCollector {
            onStreamFinished: shell.hostname = text.trim()
        }

    }

    // keyboard layout shown in the password field; Mod+Space switches it like on the desktop
    Process {
        running: true
        command: ["niri", "msg", "-j", "event-stream"]

        stdout: SplitParser {
            property var names: []

            onRead: (line) => {
                let ev;
                try {
                    ev = JSON.parse(line);
                } catch (e) {
                    return ;
                }
                if (ev.KeyboardLayoutsChanged) {
                    names = ev.KeyboardLayoutsChanged.keyboard_layouts.names;
                    shell.layout = names[ev.KeyboardLayoutsChanged.keyboard_layouts.current_idx] || "";
                } else if (ev.KeyboardLayoutSwitched) {
                    shell.layout = names[ev.KeyboardLayoutSwitched.idx] || "";
                }
            }
        }

    }

    Process {
        id: power
    }

    // greetd normally answers at once; don't leave the field locked if it never does
    Timer {
        id: stuck

        interval: 15000
        onTriggered: {
            shell.note("no answer from greetd in 15 s, state: " + Greetd.state);
            shell.fail("Нет ответа от greetd");
        }
    }

    Component.onCompleted: shell.note("started, greetd available: " + Greetd.available)

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: shell.now = new Date()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            // the password box lives on the first screen only
            readonly property bool primary: modelData === Quickshell.screens[0]

            screen: modelData
            color: shell.bg
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "minflair-greeter"
            WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            // without it Qt never activates the window, so the password field gets no keys
            focusable: primary

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Image {
                anchors.fill: parent
                source: "file://" + shell.shared + "/wallpaper.jpg"
                sourceSize: Qt.size(480, 270)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                layer.enabled: true

                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1
                    blurMax: 48
                }

            }

            Rectangle {
                anchors.fill: parent
                color: shell.bg
                opacity: 0.7
            }

            // faint grid, like the lock screen
            Item {
                anchors.fill: parent
                opacity: 0.03

                Repeater {
                    model: Math.ceil(parent.width / 72)

                    Rectangle {
                        required property int index

                        x: index * 72
                        width: 1
                        height: parent.height
                        color: shell.fg
                    }

                }

                Repeater {
                    model: Math.ceil(parent.height / 72)

                    Rectangle {
                        required property int index

                        y: index * 72
                        width: parent.width
                        height: 1
                        color: shell.fg
                    }

                }

            }

            ColumnLayout {
                visible: win.primary
                anchors.centerIn: parent
                spacing: 48

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        Text {
                            text: Qt.formatTime(shell.now, "HH")
                            font.family: shell.fontFamily
                            font.pixelSize: 112
                            font.weight: Font.DemiBold
                            color: shell.fg
                        }

                        Text {
                            text: ":"
                            font.family: shell.fontFamily
                            font.pixelSize: 112
                            font.weight: Font.Light
                            color: shell.accent
                            opacity: shell.now.getSeconds() % 2 ? 0.25 : 1

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 300
                                }

                            }

                        }

                        Text {
                            text: Qt.formatTime(shell.now, "mm")
                            font.family: shell.fontFamily
                            font.pixelSize: 112
                            font.weight: Font.Light
                            color: shell.accent
                        }

                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: shell.now.toLocaleDateString(Qt.locale("ru_RU"), "ddd · d MMMM · yyyy").toUpperCase()
                        font.family: shell.fontFamily
                        font.pixelSize: 16
                        font.letterSpacing: 3
                        font.bold: true
                        color: shell.muted
                    }

                }

                // the login card
                Rectangle {
                    id: card

                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 380
                    implicitHeight: cardCol.implicitHeight + 40
                    radius: 16
                    color: shell.bg
                    border.width: 1
                    border.color: shell.failed ? shell.accentAlt : shell.border

                    transform: Translate {
                        id: shakeOffset
                    }

                    SequentialAnimation {
                        id: shake

                        NumberAnimation { target: shakeOffset; property: "x"; to: -10; duration: 50 }
                        NumberAnimation { target: shakeOffset; property: "x"; to: 10; duration: 50 }
                        NumberAnimation { target: shakeOffset; property: "x"; to: -6; duration: 50 }
                        NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
                    }

                    ColumnLayout {
                        id: cardCol

                        anchors.centerIn: parent
                        width: parent.width - 40
                        spacing: 16

                        RowLayout {
                            spacing: 14

                            Rectangle {
                                implicitWidth: 52
                                implicitHeight: 52
                                radius: 26
                                color: "transparent"
                                border.color: shell.accent
                                border.width: 1.5

                                Rectangle {
                                    id: avatarInner

                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
                                    radius: 22
                                    color: shell.surface
                                    clip: true

                                    Text {
                                        anchors.centerIn: parent
                                        visible: face.status !== Image.Ready
                                        text: shell.user ? shell.user.charAt(0).toUpperCase() : "?"
                                        font.family: shell.fontFamily
                                        font.pixelSize: 20
                                        font.bold: true
                                        color: shell.accent
                                    }

                                    Image {
                                        id: face

                                        anchors.fill: parent
                                        source: "file://" + shell.shared + "/face"
                                        fillMode: Image.PreserveAspectCrop
                                        visible: false
                                        cache: false
                                    }

                                    MultiEffect {
                                        anchors.fill: face
                                        source: face
                                        visible: face.status === Image.Ready
                                        maskEnabled: true
                                        maskSource: faceMask
                                    }

                                    Rectangle {
                                        id: faceMask

                                        anchors.fill: parent
                                        radius: 22
                                        visible: false
                                        layer.enabled: true
                                    }

                                }

                            }

                            ColumnLayout {
                                spacing: 2

                                Text {
                                    text: shell.user || "…"
                                    font.family: shell.fontFamily
                                    font.pixelSize: 17
                                    font.bold: true
                                    color: shell.fg
                                }

                                Text {
                                    text: "@" + (shell.hostname || "arch")
                                    font.family: shell.fontFamily
                                    font.pixelSize: 13
                                    color: shell.muted
                                }

                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            radius: 12
                            color: shell.surface
                            border.width: passwordField.activeFocus ? 2 : 1
                            border.color: shell.failed ? shell.accentAlt : (passwordField.activeFocus ? shell.accent : shell.border)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 10

                                TextField {
                                    id: passwordField

                                    Layout.fillWidth: true
                                    focus: win.primary
                                    enabled: !shell.busy
                                    echoMode: TextInput.Password
                                    passwordCharacter: "•"
                                    placeholderText: shell.busy ? "Вход…" : "Пароль"
                                    placeholderTextColor: shell.busy ? shell.accent : shell.muted
                                    color: shell.fg
                                    selectionColor: shell.accent
                                    font.family: shell.fontFamily
                                    font.pixelSize: 15
                                    background: null
                                    leftPadding: 0
                                    onAccepted: shell.login(text)
                                    onTextChanged: {
                                        if (text !== "")
                                            shell.failed = false;

                                    }
                                    Keys.onEscapePressed: text = ""
                                    Component.onCompleted: forceActiveFocus()

                                    Connections {
                                        function onResetField() {
                                            passwordField.text = "";
                                            passwordField.forceActiveFocus();
                                            shake.restart();
                                        }

                                        target: shell
                                    }
                                }

                                // the same as Enter, for the mouse
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: passwordField.text !== "" ? shell.accent : "transparent"
                                    border.width: passwordField.text !== "" ? 0 : 1
                                    border.color: shell.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "→"
                                        font.family: shell.fontFamily
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: passwordField.text !== "" ? shell.bg : shell.muted
                                    }

                                    TapHandler {
                                        cursorShape: Qt.PointingHandCursor
                                        onTapped: shell.login(passwordField.text)
                                    }

                                }

                                Text {
                                    visible: shell.layout !== ""
                                    text: shell.layout.slice(0, 2).toUpperCase()
                                    font.family: shell.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: shell.muted
                                }

                            }

                        }

                        Text {
                            Layout.fillWidth: true
                            visible: shell.message !== ""
                            text: shell.message
                            wrapMode: Text.Wrap
                            font.family: shell.fontFamily
                            font.pixelSize: 13
                            color: shell.accentAlt
                        }

                    }

                }

            }

            // power buttons in the corner
            Row {
                visible: win.primary
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 32
                spacing: 12

                Repeater {
                    model: [{
                        "label": "Перезагрузка",
                        "cmd": ["systemctl", "reboot"]
                    }, {
                        "label": "Выключение",
                        "cmd": ["systemctl", "poweroff"]
                    }]

                    Rectangle {
                        required property var modelData

                        implicitWidth: label.implicitWidth + 32
                        implicitHeight: 36
                        radius: 18
                        color: hover.hovered ? shell.surface : "transparent"
                        border.width: 1
                        border.color: shell.border

                        Text {
                            id: label

                            anchors.centerIn: parent
                            text: parent.modelData.label
                            font.family: shell.fontFamily
                            font.pixelSize: 13
                            color: hover.hovered ? shell.fg : shell.muted
                        }

                        HoverHandler {
                            id: hover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
                                power.command = parent.modelData.cmd;
                                power.running = true;
                            }
                        }

                    }

                }

            }

        }

    }

}
