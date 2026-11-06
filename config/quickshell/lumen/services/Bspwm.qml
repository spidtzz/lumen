pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live bspwm state from `bspc subscribe report`.
// monitors: [{ name, focused, layout, desktops: [{ name, focused, occupied, urgent }] }]
Singleton {
    id: root

    property var monitors: []

    function monitor(name) {
        return monitors.find(m => m.name === name) ?? null;
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
                cur = { name: v, focused: k === "M", layout: "tiled", desktops: [] };
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
            }
        }
        root.monitors = mons;
    }

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
