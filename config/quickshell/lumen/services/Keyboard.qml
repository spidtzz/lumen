pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Keyboard layouts in use and which one is active (the first in
// `setxkbmap -query`; lumen switches by rotating the list).
Singleton {
    id: root

    readonly property var layouts: (Theme.conf.kb_layouts || "us").split(",")
    property string current: layouts[0]

    readonly property var names: ({
        us: "English (US)", gb: "English (UK)", ir: "Persian", ara: "Arabic", tr: "Turkish",
        de: "German", fr: "French", es: "Spanish", it: "Italian", pt: "Portuguese",
        br: "Portuguese (Brazil)", ru: "Russian", ua: "Ukrainian", pl: "Polish", nl: "Dutch",
        se: "Swedish", no: "Norwegian", dk: "Danish", fi: "Finnish", gr: "Greek",
        il: "Hebrew", "in": "Hindi", jp: "Japanese", kr: "Korean",
        af: "Dari / Pashto (Afghanistan)", pk: "Urdu", az: "Azerbaijani", kz: "Kazakh",
        cz: "Czech", sk: "Slovak", hu: "Hungarian", ro: "Romanian", bg: "Bulgarian",
        rs: "Serbian", hr: "Croatian", ch: "Swiss", be: "Belgian", th: "Thai",
        vn: "Vietnamese", cn: "Chinese", ca: "Canadian (French)", ge: "Georgian", am: "Armenian"
    })
    readonly property var shortNames: ({ us: "EN", gb: "GB", ir: "FA", ara: "AR", il: "HE", "in": "HI", jp: "JA", kr: "KO", se: "SV", dk: "DA", gr: "EL", br: "PT", pk: "UR", af: "AF", cz: "CS", rs: "SR", vn: "VI", cn: "ZH", ge: "KA", am: "HY", ua: "UK" })

    function nameOf(code) { return names[code] || code; }
    function shortOf(code) { return shortNames[code] || code.toUpperCase(); }

    // Asked again while a look is under way: look once more afterwards, so
    // the last change is never missed.
    property bool again: false
    function refresh() {
        if (query.running) again = true;
        else query.running = true;
    }
    function next() { Quickshell.execDetached(["lumen-settings", "layout-next"]); }
    function set(code) { Quickshell.execDetached(["lumen-settings", "layout-set", code]); }

    onLayoutsChanged: refresh()
    // Changing the switch keys loads the layouts again.
    readonly property string switchKeys: (Theme.conf.kb_switch || "") + (Theme.conf.kb_switch_custom || "")
    onSwitchKeysChanged: refreshSoon.restart()
    Timer { id: refreshSoon; interval: 600; onTriggered: root.refresh() }
    // And now and then anyway, for changes made outside lumen.
    Timer { interval: 10000; running: true; repeat: true; onTriggered: root.refresh() }

    Process {
        id: query
        command: ["setxkbmap", "-query"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/^layout:\s*(\S+)/m);
                if (m) root.current = m[1].split(",")[0];
            }
        }
        onExited: if (root.again) { root.again = false; Qt.callLater(() => query.running = true); }
    }
}
