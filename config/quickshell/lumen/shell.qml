import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.bar

// lumen — a desktop shell for bspwm.
// Run with: quickshell -c lumen   (bspwmrc starts it automatically)
ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // Reserve space for the bar on its edge only. bspwm's padding is global,
    // so this runs once rather than per screen.
    function syncPadding() {
        for (const e of ["top", "bottom", "left", "right"])
            Quickshell.execDetached(["bspc", "config", e + "_padding",
                String(e === Theme.barPosition ? Theme.barThickness : 0)]);
    }

    Connections {
        target: Theme
        function onBarPositionChanged() { root.syncPadding(); }
    }

    Component.onCompleted: syncPadding()

    // Called by lumen-avatar after the picture changes.
    IpcHandler {
        target: "avatar"
        function changed(): void { Theme.avatarRevision++; }
    }

    // `qs -c lumen ipc call shell reload` — handy while testing.
    IpcHandler {
        target: "shell"
        function reload(): void { Quickshell.reload(true); }
    }
}
