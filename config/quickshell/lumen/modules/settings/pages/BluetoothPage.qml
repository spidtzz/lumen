import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.components

// Bluetooth: on/off and searching on top, then your devices (paired) and
// devices nearby (to pair), each with an icon for what it is.
Page {
    id: page
    title: "Bluetooth"
    description: "Connect headphones, speakers, mice, keyboards and phones."

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter !== null && adapter.enabled
    readonly property var all: adapter ? adapter.devices.values.slice() : []
    readonly property var mine: all.filter(d => d.paired)
        .sort((a, b) => (b.connected - a.connected) || String(a.name).localeCompare(String(b.name)))
    readonly property var nearby: all.filter(d => !d.paired && (d.name || "") !== "")
        .sort((a, b) => String(a.name).localeCompare(String(b.name)))

    // Icon from what BlueZ says the device is.
    function iconFor(d) {
        const i = String(d.icon || "");
        if (/audio-head|headset|headphone/.test(i)) return "headphones";
        if (/audio|speaker/.test(i)) return "speaker";
        if (/mouse/.test(i)) return "mouse";
        if (/keyboard/.test(i)) return "keyboard";
        if (/phone/.test(i)) return "smartphone";
        if (/joystick|gaming|gamepad/.test(i)) return "gamepad";
        if (/computer|laptop/.test(i)) return "laptop";
        return "bluetooth";
    }

    // Stop searching when leaving the page.
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    Card {
        visible: page.adapter === null
        title: "No Bluetooth adapter"
        description: "This computer has no Bluetooth adapter, or the Bluetooth service isn't running. Install bluez and run: sudo systemctl enable --now bluetooth"
    }

    // ---- status ----
    Card {
        visible: page.adapter !== null
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Rectangle {
                implicitWidth: 56
                implicitHeight: 56
                radius: Theme.r(16)
                color: page.btOn ? Theme.accent : Theme.field
                Icon { anchors.centerIn: parent; name: "bluetooth"; size: 26; color: page.btOn ? Theme.accentFg : Theme.muted }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Txt { text: page.btOn ? "Bluetooth is on" : "Bluetooth is off"; size: 20; strong: true }
                Txt {
                    text: !page.btOn ? "Turn it on to use wireless devices."
                        : "Adapter: " + (page.adapter.name || "built in")
                    muted: true
                    Layout.fillWidth: true
                }
            }
            Toggle {
                checked: page.btOn
                onToggled: c => page.adapter.enabled = c
            }
        }
    }

    // ---- your devices ----
    Card {
        visible: page.btOn && page.mine.length > 0
        title: "Your devices"
        Repeater {
            model: page.mine
            delegate: DeviceRow {}
        }
    }

    // ---- nearby ----
    Card {
        visible: page.btOn
        title: "Nearby devices"
        description: page.adapter && page.adapter.discovering
            ? "Searching… put the device in pairing mode."
            : "Search to find devices to pair."

        SettingRow {
            icon: "search"
            label: page.adapter && page.adapter.discovering ? "Searching" : "Search for devices"
            Btn {
                text: page.adapter && page.adapter.discovering ? "Stop" : "Search"
                icon: "refresh"
                variant: page.adapter && page.adapter.discovering ? "normal" : "primary"
                busy: page.adapter !== null && page.adapter.discovering
                onClicked: page.adapter.discovering = !page.adapter.discovering
            }
        }
        Repeater {
            model: page.nearby
            delegate: DeviceRow {}
        }
        Txt {
            visible: page.nearby.length === 0 && page.adapter !== null && page.adapter.discovering
            text: "Nothing found yet."
            muted: true
            size: 13
        }
    }

    component DeviceRow: Rectangle {
        id: row
        required property var modelData
        readonly property var d: modelData

        Layout.fillWidth: true
        implicitHeight: rowLayout.implicitHeight + 20
        radius: Theme.radiusSmall
        color: Theme.field
        border.width: d.connected ? 2 : 1
        border.color: d.connected ? Theme.accent : Theme.line

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: Theme.r(10)
                color: row.d.connected ? Theme.accent : Theme.panel
                Icon { anchors.centerIn: parent; name: page.iconFor(row.d); size: 18; color: row.d.connected ? Theme.accentFg : Theme.ink }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { Layout.fillWidth: true; text: row.d.name || row.d.address; strong: true; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                Txt {
                    text: (row.d.connected ? "Connected" : row.d.pairing ? "Pairing…" : row.d.paired ? "Not connected" : "Ready to pair")
                        + (row.d.batteryAvailable ? "  ·  battery " + Math.round(row.d.battery * 100) + "%" : "")
                    size: 12
                    muted: true
                }
            }
            Btn {
                visible: !row.d.paired
                text: "Pair"
                variant: "primary"
                busy: row.d.pairing
                onClicked: row.d.pair()
            }
            Btn {
                visible: row.d.paired
                text: row.d.connected ? "Disconnect" : "Connect"
                variant: row.d.connected ? "normal" : "primary"
                onClicked: row.d.connected ? row.d.disconnect() : row.d.connect()
            }
            Btn {
                visible: row.d.paired
                icon: "trash"
                variant: "ghost"
                onClicked: row.d.forget()
            }
        }
    }
}
