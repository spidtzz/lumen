pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The screenshot / recording overlay (Print). Opening it first takes a still
// picture of the screen (lumen-capture freeze), so the overlay can show the
// screen as it was, menus and all, and knows where the windows are.
// The choices made in it are kept in settings.conf and come back next time.
Singleton {
    id: root

    property bool open: false
    property bool starting: false
    property var info: null   // { image, monitor: {name,x,y,w,h}, windows: [...], focused }

    // ---- remembered configuration ----
    readonly property var conf: Theme.conf
    readonly property string mode: conf.capture_mode === "record" ? "record" : "shot"
    readonly property string target: ["area", "window", "screen"].includes(conf.capture_target) ? conf.capture_target : "area"
    readonly property int delay: [0, 3, 5, 10].includes(parseInt(conf.capture_delay)) ? parseInt(conf.capture_delay) : 0
    readonly property bool pointer: conf.capture_pointer === "true"
    readonly property bool audio: conf.capture_audio === "true"
    readonly property bool save: conf.capture_save !== "false"   // screenshots: copy and save, or copy only
    readonly property string area: conf.capture_area ?? ""
    function set(key, value) {
        if (String(conf["capture_" + key]) !== String(value))
            Theme.setValue("capture_" + key, value);
    }

    function toggle() {
        if (open || starting) close();
        else start();
    }
    function start() {
        const hadPopup = Panels.popup !== "";
        Panels.closePopup();
        Panels.launcherOpen = false;
        Panels.clipboardOpen = false;
        starting = true;
        // Let a closing popup leave the screen before the picture is taken.
        settle.interval = hadPopup ? Theme.animNormal + 60 : 1;
        settle.restart();
    }
    function close() {
        open = false;
        starting = false;
        settle.stop();
    }

    // Close the overlay and run lumen-capture (it waits for the overlay to go).
    function run(args) {
        close();
        Quickshell.execDetached(["lumen-capture"].concat(args));
    }

    Timer {
        id: settle
        onTriggered: freezer.running = true
    }

    Process {
        id: freezer
        command: ["lumen-capture", "freeze"]
        stdout: StdioCollector {
            onStreamFinished: {
                let info = null;
                try { info = JSON.parse(text); } catch (e) { info = null; }
                if (!root.starting) return;   // cancelled meanwhile
                root.starting = false;
                if (info && info.image && info.monitor) {
                    root.info = info;
                    root.open = true;
                } else {
                    console.warn("lumen: lumen-capture freeze failed:", text);
                }
            }
        }
    }
}
