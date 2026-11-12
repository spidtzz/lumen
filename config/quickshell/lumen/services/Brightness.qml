pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness. Built-in screens (laptops) through brightnessctl;
// otherwise external monitors over DDC/CI through ddcutil (most monitors
// support it; ddcutil is in the recommended packages). `available` is false
// when neither works (a VM, a monitor without DDC).
Singleton {
    id: root

    property bool available: false
    property string method: ""        // "backlight" | "ddc" | ""
    property var ddcDisplays: []      // ddcutil display numbers
    property real value: 1            // 0..1
    property real pending: -1

    // Re-reads the level (quick settings calls this when it opens). Only for
    // built-in screens: talking to a monitor over DDC takes a moment and can
    // make the whole desktop hitch, so monitors are read once at login and
    // after that lumen keeps track of the level itself (every change made
    // from lumen goes through set()).
    function refresh() {
        if (method === "ddc" || ddcDetect.running) return;
        query.running = true;
    }

    // Called while dragging; applied at most every 60 ms (backlight) or
    // 350 ms (DDC, which is slow).
    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        pending = value;
        if (!throttle.running) throttle.start();
    }

    Timer {
        id: throttle
        interval: root.method === "ddc" ? 350 : 60
        onTriggered: {
            if (root.pending < 0) return;
            const pct = Math.round(root.pending * 100);
            if (root.method === "backlight") {
                Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", pct + "%"]);
            } else if (root.method === "ddc") {
                // every monitor at once
                const cmds = root.ddcDisplays.map(d => "ddcutil --display " + d + " setvcp 10 " + pct + " --noverify &").join(" ");
                Quickshell.execDetached(["sh", "-c", cmds + " wait"]);
            }
            root.pending = -1;
        }
    }

    // Backlight first. Output: device,class,current,percent,max
    Process {
        id: query
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5 && +f[4] > 0) {
                    root.method = "backlight";
                    root.available = true;
                    root.value = +f[2] / +f[4];
                } else {
                    ddcDetect.running = true;
                }
            }
        }
        onExited: code => { if (code !== 0) ddcDetect.running = true; }
    }

    // Then DDC/CI: which displays answer, and the first one's brightness.
    // Prints "D <n>" per display and "V <current> <max>".
    Process {
        id: ddcDetect
        command: ["sh", "-c",
            "command -v ddcutil >/dev/null || exit 1; " +
            "for d in $(ddcutil detect --brief 2>/dev/null | sed -n 's/^Display \\([0-9]*\\).*/\\1/p'); do echo \"D $d\"; done; " +
            "ddcutil getvcp 10 --brief 2>/dev/null | awk '$1 == \"VCP\" { print \"V\", $4, $5 }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const ds = [];
                let cur = -1, max = 0;
                for (const l of text.split("\n")) {
                    const f = l.trim().split(/\s+/);
                    if (f[0] === "D") ds.push(f[1]);
                    else if (f[0] === "V") { cur = +f[1]; max = +f[2]; }
                }
                root.ddcDisplays = ds;
                if (ds.length > 0 && max > 0) {
                    root.method = "ddc";
                    root.available = true;
                    root.value = cur / max;
                } else {
                    root.method = "";
                    root.available = false;
                }
            }
        }
    }
}
