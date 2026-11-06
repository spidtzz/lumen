pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Connected screens from `xrandr --query`, and applying changes to them.
// outputs: [{ name, primary, enabled, x, y, rotation,
//             mode, rate, modes: [{ size, rates: [..], preferred }] }]
Singleton {
    id: root

    property var outputs: []
    property bool loaded: false
    property bool applying: false
    property string lastError: ""
    signal applied(bool ok)

    function refresh() { query.running = true; }

    function parse(text) {
        const outs = [];
        let cur = null;
        for (const line of text.split("\n")) {
            const o = line.match(/^(\S+) (connected|disconnected)( primary)?(?: (\d+)x(\d+)\+(\d+)\+(\d+))?(?: (left|right|inverted))?/);
            if (o) {
                cur = null;
                if (o[2] !== "connected")
                    continue;
                cur = {
                    name: o[1], primary: !!o[3], enabled: o[4] !== undefined,
                    x: +(o[6] || 0), y: +(o[7] || 0), rotation: o[8] || "normal",
                    mode: "", rate: "", modes: []
                };
                outs.push(cur);
                continue;
            }
            const m = cur && line.match(/^\s+(\d+x\d+)i?\s+(.*)$/);
            if (!m)
                continue;
            const mode = { size: m[1], rates: [], preferred: false };
            const re = /(\d+\.\d+)(\*?)( ?\+)?/g;
            let r;
            while ((r = re.exec(m[2])) !== null) {
                if (!mode.rates.includes(r[1]))
                    mode.rates.push(r[1]);
                if (r[2] === "*") { cur.mode = m[1]; cur.rate = r[1]; }
                if (r[3]) mode.preferred = true;
            }
            if (!cur.modes.some(x => x.size === mode.size))
                cur.modes.push(mode);
        }
        outputs = outs;
        loaded = true;
    }

    // xrandr arguments describing a list of output states (as in `outputs`,
    // plus optional `relation`/`relativeTo` for placement).
    function buildArgs(list) {
        const a = [];
        for (const o of list) {
            a.push("--output", o.name);
            if (!o.enabled || o.mode === "") {
                a.push("--off");
                continue;
            }
            a.push("--mode", o.mode);
            if (o.rate !== "")
                a.push("--rate", o.rate);
            a.push("--rotate", o.rotation);
            if (o.primary)
                a.push("--primary");
            if (o.relation && o.relativeTo && o.relativeTo !== o.name)
                a.push("--" + o.relation, o.relativeTo);
            else
                a.push("--pos", o.x + "x" + o.y);
        }
        return a;
    }

    function apply(args) {
        lastError = "";
        applying = true;
        runner.command = ["xrandr"].concat(args);
        runner.running = true;
    }

    // Remember a layout for the next login.
    function save(args) {
        Quickshell.execDetached(["lumen-settings", "display-save"].concat(args));
    }

    function resetAutomatic() {
        Quickshell.execDetached(["lumen-settings", "display-reset"]);
        apply(outputs.reduce((a, o) => a.concat(["--output", o.name, "--auto"]), []));
    }

    Process {
        id: query
        command: ["xrandr", "--query"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Process {
        id: runner
        stderr: StdioCollector { id: runnerErr }
        onExited: (code, status) => {
            root.applying = false;
            if (code !== 0)
                root.lastError = runnerErr.text.trim() || "xrandr failed";
            root.refresh();
            root.applied(code === 0);
        }
    }

    Component.onCompleted: refresh()
}
