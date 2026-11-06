pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager state through nmcli.
// devices:  [{ name, type, state, connection }]
// networks: [{ ssid, signal, secure, active }]
Singleton {
    id: root

    property bool available: true
    property var devices: []
    property var networks: []
    property bool wifiEnabled: false
    property bool scanning: false
    property bool busy: false
    property string lastError: ""

    readonly property bool hasWifi: devices.some(d => d.type === "wifi")

    function refresh() {
        devProc.running = true;
        radioProc.running = true;
    }
    function scan() {
        if (!hasWifi || scanning) return;
        scanning = true;
        wifiProc.running = true;
    }
    function connect(ssid, password) {
        const cmd = ["nmcli", "device", "wifi", "connect", ssid];
        if (password) cmd.push("password", password);
        run(cmd);
    }
    function connectDevice(dev) { run(["nmcli", "device", "connect", dev]); }
    function disconnectDevice(dev) { run(["nmcli", "device", "disconnect", dev]); }
    function setWifi(on) { run(["nmcli", "radio", "wifi", on ? "on" : "off"]); }

    function run(cmd) {
        lastError = "";
        busy = true;
        action.command = cmd;
        action.running = true;
    }

    // nmcli -t escapes ":" inside fields as "\:".
    function splitTerse(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue; }
            if (c === ":") { out.push(cur); cur = ""; continue; }
            cur += c;
        }
        out.push(cur);
        return out;
    }

    Process {
        id: check
        command: ["sh", "-c", "command -v nmcli"]
        running: true
        onExited: code => {
            root.available = code === 0;
            if (root.available) root.refresh();
        }
    }

    Process {
        id: devProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.devices = text.split("\n").filter(l => l !== "").map(l => {
                    const f = root.splitTerse(l);
                    return { name: f[0], type: f[1], state: f[2], connection: f[3] || "" };
                }).filter(d => d.type === "ethernet" || d.type === "wifi");
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                const best = {};
                for (const l of text.split("\n")) {
                    if (l === "") continue;
                    const f = root.splitTerse(l);
                    const n = { active: f[0] === "*", ssid: f[1], signal: +f[2] || 0, secure: (f[3] || "") !== "" && f[3] !== "--" };
                    if (n.ssid === "") continue;
                    const prev = best[n.ssid];
                    if (!prev || n.active || (!prev.active && n.signal > prev.signal)) best[n.ssid] = n;
                }
                root.networks = Object.values(best).sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
            }
        }
        onExited: root.scanning = false
    }

    Process {
        id: action
        stderr: StdioCollector { id: actionErr }
        onExited: code => {
            root.busy = false;
            if (code !== 0)
                root.lastError = actionErr.text.trim().replace(/^Error: /, "") || "nmcli failed";
            root.refresh();
            root.scan();
        }
    }
}
