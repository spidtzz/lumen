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

    property string opened: ""   // address of the device showing its details

    // BlueZ's object for a device: /org/bluez/hci0/dev_AA_BB_...
    function busPath(d) {
        return "/org/bluez/" + ((adapter && adapter.adapterId) || "hci0") + "/dev_" + String(d.address).replace(/:/g, "_");
    }
    // Set a BlueZ device property (Alias, Trusted) over D-Bus.
    function setProp(d, name, type, value) {
        Quickshell.execDetached(["busctl", "set-property", "org.bluez", busPath(d), "org.bluez.Device1", name, type, String(value)]);
    }
    function kindOf(d) {
        return ({ headphones: "Headphones", speaker: "Speaker", mouse: "Mouse", keyboard: "Keyboard",
                  smartphone: "Phone", gamepad: "Game controller", laptop: "Computer" })[iconFor(d)] || "Device";
    }

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
        description: "Click a device for details, to rename it, or to forget it."
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: page.mine
                delegate: DeviceRow {}
            }
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
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: page.nearby
                delegate: DeviceRow {}
            }
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
        readonly property bool open: page.opened === d.address && d.paired

        Layout.fillWidth: true
        implicitHeight: rowCol.implicitHeight + 16
        radius: Theme.radiusSmall
        color: Theme.field
        border.width: d.connected ? 2 : 1
        border.color: d.connected ? Theme.accent : rowHover.hovered && d.paired ? Theme.muted : Theme.line
        Behavior on implicitHeight { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
        clip: true

        HoverHandler { id: rowHover }

        ColumnLayout {
            id: rowCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            anchors.leftMargin: 10
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
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
                    // the name opens the details (the buttons don't)
                    HoverHandler { cursorShape: row.d.paired ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    TapHandler { enabled: row.d.paired; onTapped: page.opened = row.open ? "" : row.d.address }
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
                    icon: row.open ? "chevron-up" : "chevron-down"
                    variant: "ghost"
                    onClicked: page.opened = row.open ? "" : row.d.address
                }
            }

            // ---- details ----
            ColumnLayout {
                visible: row.open
                Layout.fillWidth: true
                spacing: 8

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }

                GridLayout {
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 4
                    Txt { text: "Type"; muted: true; size: 12 }
                    Txt { text: page.kindOf(row.d); size: 12 }
                    Txt { text: "Address"; muted: true; size: 12 }
                    Txt { text: row.d.address; size: 12; font.family: Theme.monoFamily }
                    Txt { visible: (row.d.deviceName || "") !== "" && row.d.deviceName !== row.d.name; text: "Its own name"; muted: true; size: 12 }
                    Txt { visible: (row.d.deviceName || "") !== "" && row.d.deviceName !== row.d.name; text: row.d.deviceName || ""; size: 12 }
                    Txt { visible: row.d.batteryAvailable; text: "Battery"; muted: true; size: 12 }
                    Txt { visible: row.d.batteryAvailable; text: Math.round(row.d.battery * 100) + "%"; size: 12 }
                    Txt { text: "Paired"; muted: true; size: 12 }
                    Txt { text: row.d.bonded ? "Yes, with a saved key" : "Yes"; size: 12 }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Field {
                        id: nameField
                        Layout.fillWidth: true
                        placeholderText: "Name"
                        text: row.d.name || ""
                        onAccepted: if (text.trim() !== "") page.setProp(row.d, "Alias", "s", text.trim())
                    }
                    Btn {
                        text: "Rename"
                        enabled: nameField.text.trim() !== "" && nameField.text.trim() !== (row.d.name || "")
                        onClicked: page.setProp(row.d, "Alias", "s", nameField.text.trim())
                    }
                    Btn {
                        text: "Reset"
                        variant: "ghost"
                        visible: (row.d.deviceName || "") !== "" && row.d.deviceName !== row.d.name
                        onClicked: { nameField.text = row.d.deviceName; page.setProp(row.d, "Alias", "s", ""); }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Txt { text: "Connect automatically"; strong: true; size: 13 }
                        Txt { text: "Let it reconnect by itself when it's turned on nearby."; muted: true; size: 12; Layout.fillWidth: true }
                    }
                    Toggle {
                        checked: row.d.trusted
                        onToggled: c => page.setProp(row.d, "Trusted", "b", c)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Btn {
                        text: "Forget this device"
                        icon: "trash"
                        variant: "danger"
                        onClicked: { page.opened = ""; row.d.forget(); }
                    }
                }
            }
        }
    }
}
