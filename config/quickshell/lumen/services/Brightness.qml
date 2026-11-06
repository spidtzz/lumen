pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen backlight through brightnessctl (laptops and other built-in screens).
// `available` is false on desktops and in virtual machines.
Singleton {
    id: root

    property bool available: false
    property real value: 1   // 0..1
    property real pending: -1

    function refresh() { query.running = true; }

    // Called while dragging; applied at most every 60 ms.
    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        pending = value;
        if (!throttle.running) throttle.start();
    }

    Timer {
        id: throttle
        interval: 60
        onTriggered: {
            if (root.pending < 0) return;
            Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(root.pending * 100) + "%"]);
            root.pending = -1;
        }
    }

    // Output: device,class,current,percent,max
    Process {
        id: query
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                root.available = f.length >= 5 && +f[4] > 0;
                if (root.available) root.value = +f[2] / +f[4];
            }
        }
        onExited: code => { if (code !== 0) root.available = false; }
    }
}
