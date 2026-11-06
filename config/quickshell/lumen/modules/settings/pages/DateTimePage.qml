import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

Page {
    id: page
    title: "Date & Time"
    description: "Time zone, network time and how the clock looks. Date formats follow your system's regional settings."

    property string timezone: ""
    property bool ntp: false
    property var zones: []
    property string error: ""

    function refresh() { info.running = true; }
    function run(cmd) {
        error = "";
        action.command = cmd;
        action.running = true;
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Process {
        id: info
        command: ["timedatectl", "show", "-p", "Timezone", "-p", "NTP"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                for (const l of text.split("\n")) {
                    if (l.startsWith("Timezone=")) page.timezone = l.slice(9);
                    if (l.startsWith("NTP=")) page.ntp = l.slice(4) === "yes";
                }
            }
        }
    }
    Process {
        id: zoneList
        command: ["timedatectl", "list-timezones"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: page.zones = text.split("\n").filter(z => z !== "").map(z => ({ label: z.replace(/_/g, " "), value: z }))
        }
    }
    Process {
        id: action
        stderr: StdioCollector { id: actionErr }
        onExited: code => {
            if (code !== 0)
                page.error = actionErr.text.trim() || "The change was cancelled.";
            page.refresh();
        }
    }

    Card {
        ColumnLayout {
            spacing: 2
            Txt {
                text: Theme.clock24h ? Qt.formatDateTime(clock.date, "HH:mm:ss")
                                     : Qt.formatDateTime(clock.date, "h:mm:ss AP")
                size: 44
                strong: true
            }
            Txt { text: clock.date.toLocaleDateString(Qt.locale(), Locale.LongFormat); muted: true; size: 16 }
        }
    }

    Card {
        visible: page.error !== ""
        title: "Couldn't change the time settings"
        description: page.error
    }

    Card {
        title: "Time zone"
        description: "Changing it asks for your password."
        SettingRow {
            label: "Time zone"
            description: page.timezone
            Dropdown {
                implicitWidth: 300
                searchable: true
                options: page.zones
                value: page.timezone
                placeholder: "Loading…"
                onPicked: v => page.run(["timedatectl", "set-timezone", v])
            }
        }
        SettingRow {
            label: "Set time automatically"
            description: "Keep the clock in sync over the internet."
            Toggle {
                checked: page.ntp
                onToggled: c => page.run(["timedatectl", "set-ntp", c ? "true" : "false"])
            }
        }
    }

    Card {
        title: "Clock"
        SettingRow {
            label: "24-hour clock"
            Toggle {
                checked: Theme.clock24h
                onToggled: c => Theme.setValue("clock_24h", c)
            }
        }
        Txt {
            Layout.fillWidth: true
            text: "After changing the time zone, the bar clock updates the next time you log in."
            muted: true
            size: 12
        }
    }
}
