pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live bspwm state from `bspc subscribe report`.
// monitors: [{ name, focused, layout, fullscreen, desktops: [{ name, focused, occupied, urgent }] }]
// fullscreen: the focused window on that monitor's visible desktop is fullscreen.
Singleton {
    id: root

    property var monitors: []

    function monitor(name) {
        return monitors.find(m => m.name === name) ?? null;
    }

    function monitorFor(screenName) {
        return monitor(screenName) ?? (monitors.length === 1 ? monitors[0] : null);
    }

    function desktopsFor(screenName) {
        // Single-monitor VMs sometimes report a different output name than Qt;
        // fall back to the only monitor in that case.
        const m = monitor(screenName) ?? (monitors.length === 1 ? monitors[0] : null);
        return m ? m.desktops : [];
    }

    function focusDesktop(name) {
        Quickshell.execDetached(["bspc", "desktop", "-f", name]);
    }

    function cycleDesktop(forward) {
        Quickshell.execDetached(["bspc", "desktop", "-f", forward ? "next.local" : "prev.local"]);
    }

    // Report format: W<item>:<item>:... where M/m starts a monitor (focused/not),
    // O/o F/f U/u are occupied/free/urgent desktops (upper case = focused),
    // L is the layout, T the node state and G the flags.
    function parse(line) {
        if (!line.startsWith("W"))
            return;
        const mons = [];
        let cur = null;
        for (const item of line.slice(1).split(":")) {
            if (item.length === 0)
                continue;
            const k = item[0];
            const v = item.slice(1);
            if (k === "M" || k === "m") {
                cur = { name: v, focused: k === "M", layout: "tiled", fullscreen: false, desktops: [] };
                mons.push(cur);
            } else if ("OoFfUu".includes(k) && cur) {
                cur.desktops.push({
                    name: v,
                    focused: k === k.toUpperCase(),
                    occupied: "OoUu".includes(k),
                    urgent: "Uu".includes(k)
                });
            } else if (k === "L" && cur) {
                cur.layout = v === "M" ? "monocle" : "tiled";
            } else if (k === "T" && cur) {
                cur.fullscreen = v === "=";
            }
        }
        root.monitors = mons;
    }

    // Class of the focused window (WM_CLASS), "" on an empty desktop.
    property string focusedClass: ""
    property bool classPending: false

    function queryClass() {
        if (classQuery.running) { classPending = true; return; }
        classQuery.running = true;
    }

    Process {
        id: focusEvents
        command: ["bspc", "subscribe", "node_focus", "node_add", "node_remove", "node_transfer", "desktop_focus"]
        running: true
        stdout: SplitParser { onRead: data => root.queryClass() }
        onExited: focusRestart.start()
    }
    Timer { id: focusRestart; interval: 1000; onTriggered: { focusEvents.running = true; root.queryClass(); } }

    Process {
        id: classQuery
        command: ["bspc", "query", "-T", "-n", "focused.window"]
        stdout: StdioCollector {
            onStreamFinished: {
                let cls = "";
                try {
                    const t = JSON.parse(text);
                    cls = t.client ? t.client.className : "";
                } catch (e) {}
                root.focusedClass = cls;
            }
        }
        onExited: {
            if (root.classPending) {
                root.classPending = false;
                running = true;
            }
        }
    }

    Component.onCompleted: queryClass()

    Process {
        id: subscriber
        command: ["bspc", "subscribe", "report"]
        running: true
        stdout: SplitParser {
            onRead: data => root.parse(data)
        }
        // bspwm restarts (super+alt+r) end the subscription; reconnect.
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 1000
        onTriggered: subscriber.running = true
    }
}
