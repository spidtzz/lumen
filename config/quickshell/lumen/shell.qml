import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.bar
import qs.modules.settings
import qs.modules.launcher
import qs.modules.clipboard
import qs.modules.capture
import qs.modules.shortcuts
import qs.modules.session

// lumen — a desktop shell for bspwm.
// Run with: quickshell -c lumen   (bspwmrc starts it automatically)
ShellRoot {
    id: root

    // One bar per screen. Moving the bar to another edge rebuilds the bars
    // instead of re-anchoring them: an X11 panel window that changes edge
    // while open loses some of its buttons.
    property bool barsShown: true
    // Starts the automatic accent (it follows the wallpaper from here).
    readonly property bool autoAccent: AutoAccent.active
    Variants {
        model: root.barsShown && !Panels.locked ? Quickshell.screens : []
        Bar {}
    }
    Timer {
        id: rebuildTimer
        interval: 60
        onTriggered: root.barsShown = true
    }
    function rebuildBars() {
        Panels.closePopup();
        barsShown = false;
        rebuildTimer.restart();
    }

    // The notification server (popups are shown by each bar).
    Component.onCompleted: {
        syncPadding();
        Notifs.dnd;
        // The input watcher (layout switch keys, and clicks that close bar
        // popups) normally starts with bspwm; start it here too, for a shell
        // started by hand.
        startInputWatcher();
    }
    function startInputWatcher() {
        Quickshell.execDetached(["lumen-settings", "kbswitch-start"]);
    }
    // ...and again if it ever stops.
    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.startInputWatcher()
    }

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
                String(e === Theme.barPosition ? Theme.barReserve : 0)]);
    }

    Connections {
        target: Theme
        function onBarReserveChanged() { root.syncPadding(); }
        function onBarPositionChanged() { root.syncPadding(); root.rebuildBars(); }
        function onBarDepthChanged() { root.rebuildBars(); }
    }


    // Settings app, created when opened and freed when closed.
    LazyLoader {
        active: Panels.settingsOpen
        SettingsWindow {}
    }

    // super + i, or: lumen settings display
    IpcHandler {
        target: "settings"
        function toggle(): void { Panels.toggleSettings(); }
        function open(page: string): void { Panels.openSettings(page); }
        function show(): void { Panels.openSettings(Panels.settingsPage); }
        function close(): void { Panels.settingsOpen = false; }
    }
    IpcHandler {
        target: "debug"
        function bar(): string { return Panels.bars.map(b => b.debugInfo()).join("\n"); }
    }

    // Volume, brightness and media keys (sxhkdrc).
    IpcHandler {
        target: "media"
        function volumeUp(): void { Osd.volume(Osd.step); }
        function volumeDown(): void { Osd.volume(-Osd.step); }
        function mute(): void { Osd.toggleMute(); }
        function micMute(): void { Osd.toggleMic(); }
        function brightnessUp(): void { Osd.brightness(0.05); }
        function brightnessDown(): void { Osd.brightness(-0.05); }
        function playPause(): void { Osd.playPause(); }
        function next(): void { Osd.next(); }
        function previous(): void { Osd.previous(); }
        function stop(): void { Osd.stop(); }
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

    // Screenshot / recording panel (Print) and the keyboard shortcut viewer.
    LazyLoader {
        active: Capture.open
        CaptureWindow {}
    }
    LazyLoader {
        active: Panels.shortcutsOpen
        ShortcutsWindow {}
    }
    IpcHandler {
        target: "capture"
        function toggle(): void { Capture.toggle(); }
        function close(): void { Capture.close(); }
        function changed(): void { Recorder.refresh(); }
    }
    IpcHandler {
        target: "shortcuts"
        function toggle(): void { Panels.toggleShortcuts(); }
    }

    // Session menu (super + p).
    LazyLoader {
        active: Panels.sessionOpen
        SessionWindow {}
    }
    IpcHandler {
        target: "session"
        function toggle(): void { Panels.toggleSession(); }
        function open(action: string): void { Panels.openSession(action); }
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
        function setLocked(on: bool): void {
            Panels.closePopup();
            Panels.launcherOpen = false;
            Panels.clipboardOpen = false;
            Capture.close();
            Panels.shortcutsOpen = false;
            Panels.locked = on;
        }
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
