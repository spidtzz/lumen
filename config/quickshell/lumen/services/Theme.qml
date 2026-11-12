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
    property string fontFamily: "IBM Plex Sans"
    property string monoFamily: "JetBrains Mono"
    property int fontSize: 10
    readonly property real fontScale: fontSize / 10   // shell text follows the font size setting

    // Every key in settings.conf (see `lumen-settings keys`), as strings.
    property var conf: ({})
    readonly property bool clock24h: conf.clock_24h !== "false"
    // Bar clock seconds: "off", "show" (14:30:05) or "blink" (the colon flashes).
    readonly property string clockSeconds: conf.clock_seconds === "show" || conf.clock_seconds === "blink" ? conf.clock_seconds : "off"
    readonly property bool rounded: conf.corners !== "square"     // Settings > Appearance
    readonly property bool animations: conf.animations !== "false" // Settings > Performance

    // ---- bar style (Settings > Bar) and screen corners (Settings > Appearance) ----
    readonly property bool barAttached: conf.bar_style === "attached"   // edge to edge, no gap
    readonly property bool barBlack: conf.bar_black === "true"
    readonly property bool screenCorners: conf.screen_corners === "true"
    readonly property int screenRadius: 16
    // An attached bar curves into the screen at both ends when the screen has
    // rounded corners (and the theme is rounded).
    readonly property bool barFillets: barAttached && screenCorners && rounded
    // Distance from the screen edge to the bar's inner edge.
    readonly property int barOuter: barAttached ? barSize : barThickness
    // Space bspwm keeps free for the bar (bspwm adds its window gap to this,
    // so windows sit one gap from the bar, as from the screen's other edges).
    readonly property int barReserve: barAttached ? barSize : barThickness
    // Thickness of the bar's window (with room for the curved ends).
    readonly property int barDepth: barAttached ? barSize + (barFillets ? screenRadius : 0) : barThickness

    // Bar colours: the theme, or black with light content.
    readonly property color barBg: barBlack ? "#000000" : panel
    readonly property color barInk: barBlack ? "#f2f2f2" : ink
    readonly property color barMuted: barBlack ? "#9b9b9b" : muted
    readonly property color barField: barBlack ? "#1e1e1e" : field
    readonly property color barLine: barBlack ? "#000000" : line
    // On black, the dark-mode accent (light themes' accents can be too dark).
    property color darkAccent: accent
    property color darkAccentFg: accentFg
    readonly property color barAccent: barBlack ? darkAccent : accent
    readonly property color barAccentFg: barBlack ? darkAccentFg : accentFg

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

    readonly property bool dark: mode !== "light"   // dark or black

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
    // Motion: one set of durations and curves for the whole shell, all eased.
    // Settings > Performance > Animations turns them off (duration 0).
    readonly property int animFast: animations ? 150 : 0     // hover, press, colour
    readonly property int animNormal: animations ? 260 : 0   // popups, switches, pages
    readonly property int animSlow: animations ? 380 : 0     // windows, lock screen
    readonly property int easeOut: Easing.OutCubic           // things arriving
    readonly property int easeIn: Easing.InCubic             // things leaving
    readonly property int easeInOut: Easing.InOutCubic       // things moving
    readonly property int easeSpring: Easing.OutBack         // small playful pops

    // A corner radius, or 0 with square corners (Settings > Appearance).
    function r(n) { return rounded ? n : 0; }

    Behavior on bg { ColorAnimation { duration: root.animNormal; easing.type: root.easeOut } }
    Behavior on panel { ColorAnimation { duration: root.animNormal; easing.type: root.easeOut } }
    Behavior on field { ColorAnimation { duration: root.animNormal; easing.type: root.easeOut } }
    Behavior on ink { ColorAnimation { duration: root.animNormal; easing.type: root.easeOut } }
    Behavior on muted { ColorAnimation { duration: root.animNormal; easing.type: root.easeOut } }
    Behavior on line { ColorAnimation { duration: root.animNormal; easing.type: root.easeOut } }
    Behavior on accent { ColorAnimation { duration: root.animNormal; easing.type: root.easeOut } }
    Behavior on accentFg { ColorAnimation { duration: root.animNormal; easing.type: root.easeOut } }

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
            if (c.mode === "light" || c.mode === "dark" || c.mode === "black")
                root.mode = c.mode;
            if (c.accent)
                root.accentName = c.accent;
            if (["top", "bottom", "left", "right"].includes(c.bar_position))
                root.barPosition = c.bar_position;
            if (c.font)
                root.fontFamily = c.font === "Space Grotesk" ? "IBM Plex Sans" : c.font;   // no longer shipped
            if (c.mono_font)
                root.monoFamily = c.mono_font;
            if (parseInt(c.font_size) > 0)
                root.fontSize = parseInt(c.font_size);
        }
    }

    Timer { id: paletteRetry; interval: 500; onTriggered: paletteFile.reload() }

    FileView {
        path: root.dataHome + "/lumen/palettes/" + root.accentName + "-dark.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const p = root.parseConf(text());
            if (p.accent) root.darkAccent = p.accent;
            if (p.on_accent) root.darkAccentFg = p.on_accent;
        }
    }

    FileView {
        id: paletteFile
        path: root.dataHome + "/lumen/palettes/" + root.accentName + "-" + root.mode + ".conf"
        watchChanges: true
        onFileChanged: reload()
        // A new accent's palette may only be copied in a moment later (by
        // lumen-theme): try again a few times.
        property int tries: 0
        onPathChanged: tries = 0
        onLoadFailed: if (tries++ < 8) paletteRetry.restart()
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
