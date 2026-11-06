pragma Singleton

import QtQuick
import Quickshell

// Which shell windows and popups are open. shell.qml creates them on demand.
Singleton {
    id: root

    // ---- Settings app ----
    property bool settingsOpen: false
    property string settingsPage: "appearance"

    function openSettings(page) {
        if (page)
            settingsPage = page;
        popup = "";
        settingsOpen = true;
    }
    function toggleSettings() { settingsOpen ? (settingsOpen = false) : openSettings(""); }

    // ---- launcher ----
    property bool launcherOpen: false
    function toggleLauncher() {
        popup = "";
        launcherOpen = !launcherOpen;
    }

    // ---- bar popups: "", "calendar", "qs" or "tray" ----
    property string popup: ""
    property var popupScreen: null
    // The button that opened it, in screen coordinates. Empty when opened by
    // a shortcut; the popup then sits at the end of the bar.
    property rect popupAnchor: Qt.rect(0, 0, 0, 0)

    function togglePopup(name, screen, anchor) {
        const scr = screen ?? focusedScreen();
        if (popup === name && popupScreen === scr) {
            popup = "";
            return;
        }
        launcherOpen = false;
        popupScreen = scr;
        popupAnchor = anchor ?? Qt.rect(0, 0, 0, 0);
        popup = name;
    }
    function closePopup() { popup = ""; }

    // The screen bspwm has focused (for shortcuts), or the first screen.
    function focusedScreen() {
        const m = Bspwm.monitors.find(x => x.focused);
        return Quickshell.screens.find(s => m && s.name === m.name) ?? Quickshell.screens[0];
    }
}
