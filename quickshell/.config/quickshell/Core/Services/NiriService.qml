import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

// niri state over its JSON event stream:
// workspaces.values / toplevels.values / focusedWorkspace / dispatch(). Workspace ids are niri's
// per-output indexes (1, 2, 3...), which is what the bar shows and what focus-workspace takes.
Item {
    id: root

    property var _workspaces: ({})     // niri workspace id -> workspace object
    property var _windows: ({})        // niri window id -> window object
    property var _layoutNames: []
    property int _layoutIdx: 0
    property int _outputWidth: 0
    property int _outputHeight: 0

    readonly property var workspaces: ({ "values": root._workspaceList() })
    readonly property var toplevels: ({ "values": root._toplevelList() })
    readonly property var focusedWorkspace: root._focusedWorkspace()
    readonly property var focusedWindow: {
        for (const id in root._windows) {
            if (root._windows[id].is_focused)
                return root._windows[id];
        }
        return null;
    }
    readonly property string keyboardLayoutName: _layoutNames.length > _layoutIdx ? _layoutNames[_layoutIdx] : ""
    readonly property var keyboardLayoutNames: _layoutNames
    readonly property int keyboardLayoutIndex: _layoutIdx

    signal rawEvent(var event)

    function _idxOf(workspaceId) {
        const ws = root._workspaces[workspaceId];
        return ws ? ws.idx : -1;
    }

    function _workspaceList() {
        let list = [];
        for (const id in root._workspaces) {
            const ws = root._workspaces[id];
            const wins = Object.values(root._windows).filter((w) => {
                return w.workspace_id === ws.id;
            });
            list.push({
                "id": ws.idx,
                "niriId": ws.id,
                "name": ws.name,
                "output": ws.output,
                "focused": ws.is_focused,
                "active": ws.is_active,
                "toplevels": { "values": wins }
            });
        }
        list.sort((a, b) => {
            return a.id - b.id;
        });
        return list;
    }

    function _toplevelList() {
        return Object.values(root._windows).map((w) => {
            return {
                "id": w.id,
                "title": w.title,
                "appId": w.app_id,
                "workspace": { "id": root._idxOf(w.workspace_id) },
                "activated": w.is_focused
            };
        });
    }

    function _focusedWorkspace() {
        for (const id in root._workspaces) {
            const ws = root._workspaces[id];
            if (ws.is_focused) {
                // niri has no fullscreen flag in IPC: a tiled window covering the whole output is fullscreen
                const win = ws.active_window_id !== null ? root._windows[ws.active_window_id] : null;
                const size = win && win.layout ? win.layout.window_size : null;
                const full = !!size && root._outputWidth > 0 && size[0] >= root._outputWidth && size[1] >= root._outputHeight;
                return { "id": ws.idx, "niriId": ws.id, "hasFullscreen": full };
            }
        }
        return null;
    }

    // Compatibility dispatch strings mapped to niri actions
    function dispatch(cmd) {
        const m = /workspace\s*=\s*(\d+)/.exec(cmd);
        if (m) {
            focusWorkspace(parseInt(m[1]));
            return ;
        }
        console.warn("NiriService: unsupported dispatch " + cmd);
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }

    // Focus the window of the app a notification came from. The names (desktop entry, app name)
    // are compared with each window's app_id word by word, so "Telegram Desktop" finds
    // org.telegram.desktop; an exact match beats a partial one, then the most recently focused
    // window wins. Returns whether one was found.
    function focusApp(names) {
        const generic = ["org", "com", "net", "io", "app", "dev", "github", "desktop", "client", "notify", "send"];
        const words = (s) => {
            return (s || "").toLowerCase().split(/[^a-z0-9]+/).filter((w) => {
                return w.length >= 3 && generic.indexOf(w) === -1;
            });
        };
        const full = (s) => {
            return (s || "").toLowerCase().replace(/[^a-z0-9]/g, "");
        };
        const keys = [];
        for (const n of names)
            keys.push(...words(n));
        if (keys.length === 0)
            return false;

        const score = (appId) => {
            const parts = words(appId);
            for (const n of names) {
                if (full(n).length >= 3 && full(n) === full(appId))
                    return 3;

            }
            if (parts.some((p) => {
                return keys.indexOf(p) !== -1;
            }))
                return 2;

            if (parts.some((p) => {
                return keys.some((k) => {
                    return k.length >= 4 && (p.startsWith(k) || k.startsWith(p));
                });
            }))
                return 1;

            return 0;
        };
        let best = null;
        let bestScore = 0;
        let bestTime = -1;
        for (const w of Object.values(root._windows)) {
            const sc = score(w.app_id);
            if (sc === 0)
                continue;

            const t = w.focus_timestamp ? w.focus_timestamp.secs + w.focus_timestamp.nanos / 1e9 : 0;
            if (sc > bestScore || (sc === bestScore && t > bestTime)) {
                best = w;
                bestScore = sc;
                bestTime = t;
            }
        }
        if (!best)
            return false;

        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(best.id)]);
        return true;
    }

    function switchLayout(index) {
        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", String(index)]);
    }

    function quit() {
        Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
    }

    function refreshWorkspaces() {
    }

    function _apply(ev) {
        if (ev.WorkspacesChanged) {
            let map = {};
            for (const ws of ev.WorkspacesChanged.workspaces)
                map[ws.id] = ws;
            root._workspaces = map;
        } else if (ev.WorkspaceActivated) {
            const a = ev.WorkspaceActivated;
            let map = Object.assign({}, root._workspaces);
            const out = map[a.id] ? map[a.id].output : null;
            for (const id in map) {
                let ws = Object.assign({}, map[id]);
                if (ws.output === out)
                    ws.is_active = (ws.id === a.id);
                if (a.focused)
                    ws.is_focused = (ws.id === a.id);
                map[id] = ws;
            }
            root._workspaces = map;
        } else if (ev.WorkspaceActiveWindowChanged) {
            const a = ev.WorkspaceActiveWindowChanged;
            let map = Object.assign({}, root._workspaces);
            if (map[a.workspace_id])
                map[a.workspace_id] = Object.assign({}, map[a.workspace_id], { "active_window_id": a.active_window_id });
            root._workspaces = map;
        } else if (ev.WindowsChanged) {
            let map = {};
            for (const w of ev.WindowsChanged.windows)
                map[w.id] = w;
            root._windows = map;
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window;
            let map = Object.assign({}, root._windows);
            if (w.is_focused) {
                for (const id in map)
                    map[id] = Object.assign({}, map[id], { "is_focused": false });
            }
            map[w.id] = w;
            root._windows = map;
        } else if (ev.WindowClosed) {
            let map = Object.assign({}, root._windows);
            delete map[ev.WindowClosed.id];
            root._windows = map;
        } else if (ev.WindowFocusChanged) {
            const fid = ev.WindowFocusChanged.id;
            let map = {};
            for (const id in root._windows)
                map[id] = Object.assign({}, root._windows[id], { "is_focused": root._windows[id].id === fid });
            root._windows = map;
        } else if (ev.WindowLayoutsChanged) {
            let map = Object.assign({}, root._windows);
            for (const pair of ev.WindowLayoutsChanged.changes) {
                if (map[pair[0]])
                    map[pair[0]] = Object.assign({}, map[pair[0]], { "layout": pair[1] });
            }
            root._windows = map;
        } else if (ev.KeyboardLayoutsChanged) {
            root._layoutNames = ev.KeyboardLayoutsChanged.keyboard_layouts.names;
            root._layoutIdx = ev.KeyboardLayoutsChanged.keyboard_layouts.current_idx;
        } else if (ev.KeyboardLayoutSwitched) {
            root._layoutIdx = ev.KeyboardLayoutSwitched.idx;
        }
        root.rawEvent(ev);
    }

    Process {
        id: eventStream

        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        onExited: restartTimer.start()

        stdout: SplitParser {
            onRead: (line) => {
                if (!line)
                    return ;

                try {
                    root._apply(JSON.parse(line));
                } catch (e) {
                    console.warn("NiriService: bad event " + e);
                }
            }
        }

    }

    // reconnect if niri restarts the stream (e.g. after a niri reload)
    Timer {
        id: restartTimer

        interval: 1000
        onTriggered: eventStream.running = true
    }

    Process {
        id: outputsProc

        command: ["niri", "msg", "-j", "focused-output"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(this.text);
                    root._outputWidth = o.logical.width;
                    root._outputHeight = o.logical.height;
                } catch (e) {
                }
            }
        }

    }

}
