pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// "Keep awake" in Quick Settings: no screen blanking or idle lock until it's
// turned off again, you log out or the computer restarts (lumen-session
// clears it at every login; restarting bspwm keeps it). Stored as a flag in $XDG_RUNTIME_DIR so
// the idle settings (lumen-settings apply idle) respect it too.
Singleton {
    id: root

    property bool on: false

    function toggle() {
        on = !on;
        Quickshell.execDetached(["lumen-settings", "awake", on ? "on" : "off"]);
    }

    Process {
        command: ["lumen-settings", "awake", "status"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.on = text.trim() === "on" }
    }
}
