pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Whether a screen recording is running (lumen-capture), for the bar.
Singleton {
    id: root

    property bool recording: false
    property real startedAt: 0
    property string file: ""
    property int elapsed: 0   // seconds

    function refresh() { status.running = true; }
    function stop() { Quickshell.execDetached(["lumen-capture", "stop"]); }

    Process {
        id: status
        command: ["lumen-capture", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(" ");
                root.recording = f[0] === "recording";
                root.startedAt = root.recording ? Number(f[1]) * 1000 : 0;
                root.file = root.recording ? f.slice(2).join(" ") : "";
            }
        }
    }

    Timer {
        running: root.recording
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.elapsed = Math.max(0, Math.floor((Date.now() - root.startedAt) / 1000))
    }
}
