pragma Singleton

import QtQuick
import Quickshell

// Which shell windows are open. shell.qml creates them on demand.
Singleton {
    id: root

    property bool settingsOpen: false
    property string settingsPage: "appearance"

    function openSettings(page) {
        if (page)
            settingsPage = page;
        settingsOpen = true;
    }

    function toggleSettings() {
        settingsOpen = !settingsOpen;
    }
}
