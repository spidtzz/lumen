import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

Page {
    id: page
    title: "About"
    description: "This computer and lumen."

    property var info: ({})
    readonly property var rows: [
        { key: "hostname", label: "Device name" },
        { key: "os", label: "System" },
        { key: "kernel", label: "Kernel" },
        { key: "cpu", label: "Processor" },
        { key: "memory", label: "Memory" },
        { key: "gpu", label: "Graphics" },
        { key: "disk", label: "Disk" },
        { key: "uptime", label: "Up for" },
        { key: "quickshell", label: "Quickshell" }
    ]
    property bool copied: false

    Process {
        command: ["lumen-settings", "sysinfo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const l of text.split("\n")) {
                    const i = l.indexOf("=");
                    if (i > 0) o[l.slice(0, i)] = l.slice(i + 1);
                }
                page.info = o;
            }
        }
    }

    Card {
        RowLayout {
            spacing: 16
            Rectangle {
                width: 64; height: 64; radius: Theme.r(18)
                color: Theme.accent
                Icon { anchors.centerIn: parent; name: "lumen"; size: 40; stroke: 2.2; color: Theme.accentFg }
            }
            ColumnLayout {
                spacing: 2
                Txt { text: "lumen"; size: 28; strong: true }
                Txt { text: "A lightweight desktop for bspwm, built with Quickshell."; muted: true }
            }
        }
    }

    Card {
        title: "This computer"

        Repeater {
            model: page.rows.filter(r => (page.info[r.key] || "") !== "")
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 16
                Txt { text: modelData.label; muted: true; Layout.preferredWidth: 130 }
                Txt { text: page.info[modelData.key]; strong: true; Layout.fillWidth: true }
            }
        }

        RowLayout {
            spacing: 8
            Btn {
                text: page.copied ? "Copied" : "Copy details"
                icon: page.copied ? "check" : "copy"
                onClicked: {
                    Quickshell.clipboardText = page.rows
                        .filter(r => (page.info[r.key] || "") !== "")
                        .map(r => r.label + ": " + page.info[r.key]).join("\n");
                    page.copied = true;
                    copiedTimer.restart();
                }
            }
            Btn {
                text: "lumen on GitHub"
                variant: "ghost"
                onClicked: Qt.openUrlExternally("https://github.com/spidtzz/lumen")
            }
        }
        Timer { id: copiedTimer; interval: 1800; onTriggered: page.copied = false }
    }
}
