pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The single source of colours, fonts and shell settings.
// Reads ~/.config/lumen/settings.conf and the matching palette written by
// lumen-theme, and updates live whenever either file changes.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (home + "/.local/share")
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")

    // ---- settings (settings.conf) ----
    property string mode: "dark"
    property string accentName: "blue"
    property string barPosition: "top"
    property string fontFamily: "Space Grotesk"
    property string monoFamily: "JetBrains Mono"
    property int fontSize: 10
    readonly property real fontScale: fontSize / 10   // shell text follows the font size setting

    // Every key in settings.conf (see `lumen-settings keys`), as strings.
    property var conf: ({})
    readonly property bool clock24h: conf.clock_24h !== "false"
    readonly property bool rounded: conf.corners !== "square"     // Settings > Appearance
    readonly property bool animations: conf.animations !== "false" // Settings > Performance

    // ---- palette (same names as the UI demo) ----
    property color bg: "#070f1f"
    property color panel: "#101a2d"
    property color field: "#0b1423"
    property color ink: "#ebeff5"
    property color muted: "#97a5be"
    property color line: "#25334c"
    property color accent: "#71a3ff"
    property color accentFg: "#081123"
    property color danger: "#f75d59"
    property color success: "#53be70"
    property color warning: "#edb345"

    readonly property bool dark: mode === "dark"

    // ---- user (picture set with `lumen-avatar set <image>`) ----
    readonly property string userName: Quickshell.env("USER") || ""
    readonly property string avatarPath: home + "/.face"
    property int avatarRevision: 0   // bumped by `qs -c lumen ipc call avatar changed`

    // ---- metrics ----
    readonly property int radius: r(14)       // cards
    readonly property int radiusSmall: r(9)   // buttons, fields
    readonly property int gap: 10           // matches bspwm window_gap
    readonly property int barSize: 36       // visible bar thickness
    readonly property int barThickness: barSize + gap  // space reserved from bspwm
    readonly property int animFast: animations ? 120 : 0
    readonly property int animNormal: animations ? 180 : 0

    // A corner radius, or 0 with square corners (Settings > Appearance).
    function r(n) { return rounded ? n : 0; }

    Behavior on bg { ColorAnimation { duration: root.animNormal } }
    Behavior on panel { ColorAnimation { duration: root.animNormal } }
    Behavior on field { ColorAnimation { duration: root.animNormal } }
    Behavior on ink { ColorAnimation { duration: root.animNormal } }
    Behavior on muted { ColorAnimation { duration: root.animNormal } }
    Behavior on line { ColorAnimation { duration: root.animNormal } }
    Behavior on accent { ColorAnimation { duration: root.animNormal } }
    Behavior on accentFg { ColorAnimation { duration: root.animNormal } }

    function parseConf(text) {
        const out = {};
        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (line === "" || line.startsWith("#"))
                continue;
            const i = line.indexOf("=");
            if (i > 0)
                out[line.slice(0, i).trim()] = line.slice(i + 1).trim();
        }
        return out;
    }

    // Save and apply a setting. The change comes back through the file
    // watcher below; `conf` is updated right away so controls feel instant.
    function setValue(key, value) {
        const c = Object.assign({}, conf);
        c[key] = String(value);
        conf = c;
        Quickshell.execDetached(["lumen-settings", "set", key, String(value)]);
    }

    FileView {
        id: settingsFile
        path: root.configHome + "/lumen/settings.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const c = root.parseConf(text());
            root.conf = c;
            if (c.mode === "light" || c.mode === "dark")
                root.mode = c.mode;
            if (c.accent)
                root.accentName = c.accent;
            if (["top", "bottom", "left", "right"].includes(c.bar_position))
                root.barPosition = c.bar_position;
            if (c.font)
                root.fontFamily = c.font;
            if (c.mono_font)
                root.monoFamily = c.mono_font;
            if (parseInt(c.font_size) > 0)
                root.fontSize = parseInt(c.font_size);
        }
    }

    FileView {
        id: paletteFile
        path: root.dataHome + "/lumen/palettes/" + root.accentName + "-" + root.mode + ".conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const p = root.parseConf(text());
            const map = {
                bg: "bg", panel: "panel", field: "field", ink: "ink", muted: "muted",
                line: "line", accent: "accent", on_accent: "accentFg",
                danger: "danger", success: "success", warning: "warning"
            };
            for (const key in map)
                if (p[key])
                    root[map[key]] = p[key];
        }
    }
}
