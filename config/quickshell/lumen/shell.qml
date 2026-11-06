import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.bar
import qs.modules.settings
import qs.modules.launcher
import qs.modules.clipboard

// lumen — a desktop shell for bspwm.
// Run with: quickshell -c lumen   (bspwmrc starts it automatically)
ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // The notification server (popups are shown by each bar).
    Component.onCompleted: { syncPadding(); Notifs.dnd; }

    // App launcher, created when opened.
    LazyLoader {
        active: Panels.launcherOpen
        Launcher {}
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


    // Settings app, created when opened and freed when closed.
    LazyLoader {
        active: Panels.settingsOpen
        SettingsWindow {}
    }

    // super + comma, or: qs -c lumen ipc call settings open display
    IpcHandler {
        target: "settings"
        function toggle(): void { Panels.toggleSettings(); }
        function open(page: string): void { Panels.openSettings(page); }
        function close(): void { Panels.settingsOpen = false; }
    }

    // Clipboard history, created when opened.
    LazyLoader {
        active: Panels.clipboardOpen
        ClipboardWindow {}
    }

    // super + v; lumen-clipboard calls "changed" after recording a copy.
    IpcHandler {
        target: "clipboard"
        function toggle(): void { Panels.toggleClipboard(); }
        function changed(): void { Panels.clipboardRevision++; }
    }

    // super + space
    IpcHandler {
        target: "launcher"
        function toggle(): void { Panels.toggleLauncher(); }
    }

    // Called by lumen-settings when the keyboard layout changes.
    IpcHandler {
        target: "keyboard"
        function changed(): void { Keyboard.refresh(); }
    }

    // super + n / super + c, or: qs -c lumen ipc call panels toggle qs
    IpcHandler {
        target: "panels"
        function toggle(name: string): void { Panels.togglePopup(name, null, null); }
        function close(): void { Panels.closePopup(); }
        function click(): void { Panels.click(); }
    }

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
