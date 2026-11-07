pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// "Keep awake" in Quick Settings: no screen blanking or idle lock until it's
// turned off again or you log out. Stored as a flag in $XDG_RUNTIME_DIR so
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
