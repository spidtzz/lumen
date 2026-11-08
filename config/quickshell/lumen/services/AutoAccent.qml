pragma Singleton

import QtQuick
import Quickshell

// Automatic accent (Settings > Appearance > Auto): the accent nearest to the
// wallpaper's main colour, worked out here with Quickshell's ColorQuantizer
// (no extra programs). The wallpaper is split into 16 colours that each stand
// for about the same share of the picture; those with some colour vote for
// their hue, and the winning hue picks the nearest of the accents. A picture
// with hardly any colour gets mono.
Singleton {
    id: root

    readonly property bool active: Theme.conf.accent_auto === "true" && (Theme.conf.wallpaper || "") !== ""
    property string picked: ""      // last result, for Settings and the log
    property string requested: ""   // wallpaper + pick already sent, to send once

    // Accent hues (OKLCH), as in tools/gen-palettes.py and Pane. The line
    // between red and orange sits a little lower so rust and brick count
    // as orange.
    readonly property var match: ({
        blue: 262, violet: 295, teal: 190, green: 150, orange: 48, pink: 355, red: 20,
        amber: 85, lime: 125, cyan: 215, sky: 240, indigo: 278, fuchsia: 325
    })

    ColorQuantizer {
        id: quantizer
        source: root.active ? "file://" + Theme.conf.wallpaper : ""
        depth: 4            // 16 colours
        rescaleSize: 128
        onColorsChanged: settle.restart()
    }
    // Turning Auto on again always re-applies; a short pause lets the
    // setting itself be saved first.
    onActiveChanged: { requested = ""; settle.restart(); }
    Timer { id: settle; interval: 300; onTriggered: root.decide() }

    function lin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
    function oklch(c) {
        const r = lin(c.r), g = lin(c.g), b = lin(c.b);
        const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
        const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
        const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
        const L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
        const A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
        const B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
        return { L: L, C: Math.hypot(A, B), h: (Math.atan2(B, A) * 180 / Math.PI + 360) % 360 };
    }

    function choose(colors) {
        const bins = new Array(72).fill(0);
        let colourful = 0;
        for (const c of colors) {
            const p = oklch(c);
            if (p.C < 0.03 || p.L < 0.15 || p.L > 0.97) continue;
            const w = Math.min(p.C, 0.08) / 0.08 * (1 - 0.6 * Math.abs(p.L - 0.6));
            bins[Math.floor(p.h / 5) % 72] += w;
            colourful += w;
        }
        if (colourful < 0.08 * colors.length) return "mono";
        const around = i => [-2, -1, 0, 1, 2].map(k => (i + k + 72) % 72);
        let best = 0, bestSum = -1;
        for (let i = 0; i < 72; i++) {
            const sum = around(i).reduce((a, j) => a + bins[j], 0);
            if (sum > bestSum) { best = i; bestSum = sum; }
        }
        let x = 0, y = 0;
        for (const j of around(best)) {
            const a = (j * 5 + 2.5) * Math.PI / 180;
            x += bins[j] * Math.cos(a);
            y += bins[j] * Math.sin(a);
        }
        const hue = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
        let pick = "blue", dist = 999;
        for (const name in match) {
            const d0 = Math.abs(match[name] - hue) % 360, d = Math.min(d0, 360 - d0);
            if (d < dist) { dist = d; pick = name; }
        }
        return pick;
    }

    function decide() {
        if (!active || quantizer.colors.length === 0) return;
        picked = choose(quantizer.colors);
        const key = Theme.conf.wallpaper + " " + picked;
        console.info("lumen: automatic accent:", Theme.conf.wallpaper, "->", picked);
        if (key === requested) return;
        requested = key;
        Quickshell.execDetached(["lumen-settings", "accent-auto", picked]);
    }
}
