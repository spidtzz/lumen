pragma Singleton

import QtQuick
import Quickshell

// Which shell windows and popups are open. shell.qml and Bar.qml create
// them on demand.
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

    // ---- bar popups: "", "calendar", "qs", "tray", "traymenu", "keyboard" ----
    property string popup: ""
    property var popupScreen: null
    // The button that opened it, in its bar window's coordinates. Empty when
    // opened by a shortcut; the popup then sits at the end of the bar.
    property rect popupAnchor: Qt.rect(0, 0, 0, 0)
    property var menuItem: null      // tray item whose menu is open

    // A click outside closes the popup and may land on the button that opened
    // it; don't reopen in that case.
    property string lastClosed: ""
    property real lastClosedAt: 0
    property real openedAt: 0

    // Where the pointer is, so a click there doesn't count as "outside".
    property bool popupHovered: false
    property bool barHovered: false

    // lumen-settings kbswitch reports mouse clicks while this file exists.
    readonly property string flagFile: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/lumen-popup-open"
    onPopupChanged: {
        if (popup !== "") openedAt = Date.now();
        Quickshell.execDetached(popup !== "" ? ["touch", flagFile] : ["rm", "-f", flagFile]);
        if (popup === "") popupHovered = false;
    }

    // A mouse click somewhere on screen (from the input watcher).
    function click() {
        if (popup === "" || popupHovered || barHovered) return;
        if (Date.now() - openedAt < 300) return;   // the click that opened it
        closePopup();
    }

    function togglePopup(name, screen, anchor) {
        const scr = screen ?? focusedScreen();
        if (popup === name && popupScreen === scr) {
            closePopup();
            return;
        }
        if (popup === "" && lastClosed === name && Date.now() - lastClosedAt < 350)
            return;
        launcherOpen = false;
        popupScreen = scr;
        popupAnchor = anchor ?? Qt.rect(0, 0, 0, 0);
        popup = name;
    }

    function openTrayMenu(item, screen, anchor) {
        menuItem = item;
        launcherOpen = false;
        popupScreen = screen ?? focusedScreen();
        if (anchor) popupAnchor = anchor;
        popup = "traymenu";
    }

    function closePopup() {
        if (popup === "") return;
        lastClosed = popup;
        lastClosedAt = Date.now();
        popup = "";
    }

    // The screen bspwm has focused (for shortcuts), or the first screen.
    function focusedScreen() {
        const m = Bspwm.monitors.find(x => x.focused);
        return Quickshell.screens.find(s => m && s.name === m.name) ?? Quickshell.screens[0];
    }

    Component.onCompleted: Quickshell.execDetached(["rm", "-f", flagFile])
}
