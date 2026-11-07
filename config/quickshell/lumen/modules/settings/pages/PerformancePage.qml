import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.services
import qs.components

Page {
    id: page
    title: "Performance"
    description: "Power mode, visual effects, and how busy this computer is."

    // ---- live usage, read from /proc every 1.5 s while this page is open ----
    property real cpu: -1          // 0-1
    property real memUsed: 0       // bytes
    property real memTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property real temp: -1         // °C, -1 when the system doesn't report it
    property string load: ""
    property var lastCpu: null     // [busy, total] from the previous reading

    function gib(b) { return (b / 1073741824).toFixed(1) + " GB"; }

    function parse(text) {
        const lines = text.split("\n");
        const kb = {};
        for (const l of lines) {
            if (l.startsWith("cpu ")) {
                const f = l.trim().split(/\s+/).slice(1).map(Number);
                const idle = f[3] + (f[4] || 0);
                const total = f.reduce((a, b) => a + b, 0);
                if (page.lastCpu && total > page.lastCpu[1])
                    page.cpu = 1 - (idle - page.lastCpu[0]) / (total - page.lastCpu[1]);
                page.lastCpu = [idle, total];
            } else if (l.startsWith("temp=")) {
                const t = parseInt(l.slice(5));
                page.temp = t > 0 ? t / 1000 : -1;
            } else if (l.startsWith("load=")) {
                page.load = l.slice(5).split(" ").slice(0, 3).join("  ");
            } else {
                const m = l.match(/^(\w+):\s+(\d+)/);
                if (m) kb[m[1]] = +m[2] * 1024;
            }
        }
        if (kb.MemTotal) {
            page.memTotal = kb.MemTotal;
            page.memUsed = kb.MemTotal - (kb.MemAvailable || 0);
            page.swapTotal = kb.SwapTotal || 0;
            page.swapUsed = (kb.SwapTotal || 0) - (kb.SwapFree || 0);
        }
    }

    Process {
        id: reader
        command: ["sh", "-c",
            "head -n 1 /proc/stat; grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo; " +
            "printf 'temp=%s\\n' \"$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -n 1)\"; " +
            "printf 'load=%s\\n' \"$(cat /proc/loadavg)\""]
        stdout: StdioCollector { onStreamFinished: page.parse(text) }
    }
    Timer {
        interval: 1500
        running: page.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }

    component Meter: ColumnLayout {
        id: meter
        property string label
        property string detail
        property real value: 0   // 0-1
        Layout.fillWidth: true
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Txt { text: meter.label; strong: true; Layout.fillWidth: true }
            Txt { text: meter.detail; muted: true; size: 13 }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 8
            radius: Theme.r(4)
            color: Theme.field
            border.width: 1
            border.color: Theme.line
            Rectangle {
                width: Math.max(0, Math.min(1, meter.value)) * parent.width
                height: parent.height
                radius: parent.radius
                color: meter.value > 0.9 ? Theme.danger : meter.value > 0.75 ? Theme.warning : Theme.accent
                Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ---- power mode ----
    Card {
        title: "Power mode"
        description: PowerProfiles.hasPerformanceProfile
            ? "Performance makes the processor faster and the fans louder; power saver does the opposite."
            : "This computer has no performance mode (common in virtual machines). Power saver still helps on battery."

        SettingRow {
            label: "Mode"
            Seg {
                options: [{ label: "Power saver", value: "saver" }, { label: "Balanced", value: "balanced" }]
                    .concat(PowerProfiles.hasPerformanceProfile ? [{ label: "Performance", value: "performance" }] : [])
                value: PowerProfiles.profile === PowerProfile.Performance ? "performance"
                     : PowerProfiles.profile === PowerProfile.PowerSaver ? "saver" : "balanced"
                onPicked: v => PowerProfiles.profile = v === "performance" ? PowerProfile.Performance
                                                    : v === "saver" ? PowerProfile.PowerSaver : PowerProfile.Balanced
            }
        }
    }

    // ---- effects ----
    Card {
        title: "Visual effects"
        description: "Turn these off on slow computers and virtual machines."

        SettingRow {
            label: "Compositor"
            description: "Window shadows, rounded window corners and fades (picom)."
            Toggle {
                checked: Theme.conf.compositor !== "false"
                onToggled: c => Theme.setValue("compositor", c)
            }
        }
        SettingRow {
            label: "Animations"
            description: "Motion in the bar, popups and Settings, and windows fading in and out."
            Toggle {
                checked: Theme.animations
                onToggled: c => Theme.setValue("animations", c)
            }
        }
    }

    // ---- usage ----
    Card {
        title: "Usage"
        description: page.load !== "" ? "Load average (1, 5, 15 min): " + page.load : ""

        Meter {
            label: "Processor"
            value: Math.max(0, page.cpu)
            detail: page.cpu < 0 ? "…" : Math.round(page.cpu * 100) + "%"
                  + (page.temp > 0 ? "  ·  " + Math.round(page.temp) + " °C" : "")
        }
        Meter {
            label: "Memory"
            value: page.memTotal > 0 ? page.memUsed / page.memTotal : 0
            detail: page.memTotal > 0 ? page.gib(page.memUsed) + " of " + page.gib(page.memTotal) : "…"
        }
        Meter {
            visible: page.swapTotal > 0
            label: "Swap"
            value: page.swapTotal > 0 ? page.swapUsed / page.swapTotal : 0
            detail: page.gib(page.swapUsed) + " of " + page.gib(page.swapTotal)
        }
    }
}
