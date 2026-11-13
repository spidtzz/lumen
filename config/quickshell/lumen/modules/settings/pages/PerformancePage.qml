import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.services
import qs.components

Page {
    id: page
    title: "Power & performance"
    description: "Battery, screen off and sleep, the laptop lid, power mode, visual effects, and how busy this computer is."

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

    // ---- laptop lid: systemd-logind's setting, changed with a password ----
    property var lid: ({ present: false })
    property bool lidBusy: false
    function parseLid(text) {
        const o = {};
        for (const kv of text.trim().split(/\s+/)) {
            const i = kv.indexOf("=");
            if (i > 0) o[kv.slice(0, i)] = kv.slice(i + 1);
        }
        o.present = o.present === "true";
        page.lid = o;
    }
    function setLid(which, action) {
        const next = { battery: page.lid.battery, ac: page.lid.ac, docked: page.lid.docked };
        next[which] = action;
        page.lidBusy = true;
        lidWriter.command = ["lumen-settings", "lid-set", next.battery, next.ac, next.docked];
        lidWriter.running = true;
    }
    readonly property var lidActions: [
        { label: "Suspend", value: "suspend" },
        { label: "Lock the screen", value: "lock" },
        { label: "Do nothing", value: "ignore" },
        { label: "Shut down", value: "poweroff" }
    ].concat(page.lid.hibernate === "yes" ? [
        { label: "Hibernate", value: "hibernate" },
        { label: "Suspend, then hibernate", value: "suspend-then-hibernate" }
    ] : [])
    Process {
        id: lidReader
        command: ["lumen-settings", "lid-status"]
        running: true
        stdout: StdioCollector { onStreamFinished: page.parseLid(text) }
    }
    Process {
        id: lidWriter
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") page.lidError = text.replace(/^lumen-settings: /, "").trim()
        }
        onStarted: page.lidError = ""
        onExited: {
            page.lidBusy = false;
            lidReader.running = true;
        }
    }
    property string lidError: ""

    // ---- battery (laptops) ----
    Card {
        visible: Battery.present
        title: "Battery"
        description: Battery.pluggedIn ? "Plugged in." : "On battery."

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            BatteryIcon { size: 26 }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Txt { text: Battery.percent + "%"; size: 20; strong: true; font.features: ({ "tnum": 1 }) }
                Txt { text: Battery.estimate; muted: true; size: 13; font.features: ({ "tnum": 1 }) }
            }
        }
        Txt {
            visible: Battery.dev !== null && Battery.dev.healthSupported
            text: Battery.dev && Battery.dev.healthSupported
                ? "Battery health: " + Math.round(Battery.dev.healthPercentage > 1 ? Battery.dev.healthPercentage : Battery.dev.healthPercentage * 100) + "% of its original capacity"
                : ""
            muted: true
            size: 13
        }
    }

    Card {
        title: "Screen and sleep"
        SettingRow {
            icon: "monitor"
            label: "Turn the screen off after"
            description: "When the computer has been idle this long. While locked, after a minute."
            Dropdown {
                implicitWidth: 180
                options: [
                    { label: "1 minute", value: "1" }, { label: "2 minutes", value: "2" },
                    { label: "5 minutes", value: "5" }, { label: "10 minutes", value: "10" },
                    { label: "15 minutes", value: "15" }, { label: "30 minutes", value: "30" },
                    { label: "1 hour", value: "60" }, { label: "Never", value: "0" }
                ]
                value: Theme.conf.screen_off || "15"
                onPicked: v => Theme.setValue("screen_off", v)
            }
        }
        SettingRow {
            icon: "moon"
            label: "Sleep after"
            description: "Not while sound plays, Keep awake is on, or an app asks to stay up (a video, a download)."
            Dropdown {
                implicitWidth: 180
                options: [
                    { label: "10 minutes", value: "10" }, { label: "15 minutes", value: "15" },
                    { label: "20 minutes", value: "20" }, { label: "30 minutes", value: "30" },
                    { label: "45 minutes", value: "45" }, { label: "1 hour", value: "60" },
                    { label: "1.5 hours", value: "90" }, { label: "2 hours", value: "120" },
                    { label: "3 hours", value: "180" }, { label: "Never", value: "0" }
                ]
                value: Theme.conf.sleep_after || "0"
                onPicked: v => Theme.setValue("sleep_after", v)
            }
        }
        SettingRow {
            icon: "lock"
            label: "Lock after"
            description: "Also in Settings › Users."
            Dropdown {
                implicitWidth: 180
                options: [
                    { label: "5 minutes", value: "5" }, { label: "10 minutes", value: "10" },
                    { label: "15 minutes", value: "15" }, { label: "30 minutes", value: "30" },
                    { label: "1 hour", value: "60" }, { label: "Never", value: "0" }
                ]
                value: Theme.conf.idle_lock || "10"
                onPicked: v => Theme.setValue("idle_lock", v)
            }
        }
    }

    Card {
        visible: page.lid.present === true
        title: "Laptop lid"
        description: "What happens when you close the lid. Changing it asks for your password; it also applies on the login screen."

        SettingRow {
            icon: "zap"
      label: "On battery"
            Dropdown {
                enabled: !page.lidBusy
                options: page.lidActions
                value: page.lid.battery
                onPicked: v => page.setLid("battery", v)
            }
        }
        SettingRow {
            icon: "plug"
      label: "Plugged in"
            Dropdown {
                enabled: !page.lidBusy
                options: page.lidActions
                value: page.lid.ac
                onPicked: v => page.setLid("ac", v)
            }
        }
        SettingRow {
            icon: "monitor"
      label: "With an external monitor"
            description: "Docked, or a second screen connected."
            Dropdown {
                enabled: !page.lidBusy
                options: page.lidActions
                value: page.lid.docked
                onPicked: v => page.setLid("docked", v)
            }
        }
        Txt {
            visible: page.lidError !== ""
            Layout.fillWidth: true
            text: page.lidError
            color: Theme.danger
            size: 13
        }
        RowLayout {
            visible: page.lid.custom === "true"
            Layout.fillWidth: true
            Txt { Layout.fillWidth: true; text: "Changed here. Reset goes back to the system's own setting."; muted: true; size: 13 }
            Btn {
                text: "Reset"
                variant: "ghost"
                enabled: !page.lidBusy
                onClicked: {
                    page.lidBusy = true;
                    lidWriter.command = ["lumen-settings", "lid-reset"];
                    lidWriter.running = true;
                }
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
            icon: "gauge"
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
            icon: "sparkle"
      label: "Compositor"
            description: "Window shadows, rounded window corners and fades (picom)."
            Toggle {
                checked: Theme.conf.compositor !== "false"
                onToggled: c => Theme.setValue("compositor", c)
            }
        }
        SettingRow {
            icon: "sparkle"
      label: "Animations"
            description: "Motion in the bar, popups and Settings, and windows opening, closing and switching desktops."
            Toggle {
                checked: Theme.animations
                onToggled: c => Theme.setValue("animations", c)
            }
        }
        SettingRow {
            icon: "gamepad"
      label: "Full speed for fullscreen apps"
            description: "Games and videos in fullscreen skip the compositor: smoother and with less delay. Rounded screen corners aren't drawn over them."
            Toggle {
                enabled: Theme.conf.compositor !== "false"
                checked: Theme.conf.fullscreen_direct !== "false"
                onToggled: c => Theme.setValue("fullscreen_direct", c)
            }
        }
        SettingRow {
            icon: "window"
      label: "Animate moving and resizing"
            description: "Windows glide into place when they tile, move or resize. Experimental in picom: turn off if windows flicker."
            Toggle {
                enabled: Theme.animations && Theme.conf.compositor !== "false"
                checked: Theme.conf.window_motion !== "false"
                onToggled: c => Theme.setValue("window_motion", c)
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
