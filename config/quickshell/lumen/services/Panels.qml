pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which shell windows and popups are open. shell.qml and Bar.qml create
// them on demand.
Singleton {
    id: root

    // True while the lock screen is up (set by lumen-lock): the bar, its
    // popups and notifications are hidden.
    property bool locked: false

    // The bar windows (one per screen), for `lumen debug`.
    property var bars: []

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

    // ---- session menu (super + p): lock, log out, suspend, restart, shut down ----
    property bool sessionOpen: false
    property string sessionAction: ""   // open straight at this one's "are you sure?"
    function openSession(action) {
        popup = "";
        launcherOpen = false;
        clipboardOpen = false;
        sessionAction = action || "";
        sessionOpen = true;
    }
    function toggleSession() { sessionOpen ? (sessionOpen = false) : openSession(""); }

    // ---- launcher ----
    property bool launcherOpen: false
    function toggleLauncher() {
        popup = "";
        clipboardOpen = false;
        launcherOpen = !launcherOpen;
    }

    // ---- keyboard shortcuts (the capture overlay is services/Capture.qml) ----
    property bool shortcutsOpen: false
    function toggleShortcuts() { popup = ""; shortcutsOpen = !shortcutsOpen; }

    // ---- emoji picker (super + .) ----
    property bool emojiOpen: false
    function toggleEmoji() {
        popup = "";
        launcherOpen = false;
        clipboardOpen = false;
        emojiOpen = !emojiOpen;
    }

    // ---- clipboard history ----
    property bool clipboardOpen: false
    property int clipboardRevision: 0   // bumped when lumen-clipboard records something
    function toggleClipboard() {
        popup = "";
        launcherOpen = false;
        clipboardOpen = !clipboardOpen;
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

    // While a popup is open, lumen-clickwatch reports mouse clicks anywhere.
    Process {
        running: root.popup !== ""
        command: ["lumen-clickwatch"]
        stdout: SplitParser { onRead: data => root.click() }
    }
    onPopupChanged: {
        if (popup !== "") openedAt = Date.now();
        // A popup that closes or is swapped for another can't report the
        // pointer leaving it; the new one reports when it's entered.
        popupHovered = false;
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

}
