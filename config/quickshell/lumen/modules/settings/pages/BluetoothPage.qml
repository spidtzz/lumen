import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.components

Page {
    id: page
    title: "Bluetooth"
    description: "Turn Bluetooth on, find devices and connect to them."

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter ? adapter.devices.values.slice().sort((a, b) =>
        (b.connected - a.connected) || (b.paired - a.paired) || String(a.name).localeCompare(String(b.name))) : []

    // Stop scanning when leaving the page.
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    Card {
        visible: page.adapter === null
        title: "No Bluetooth adapter"
        description: "This computer has no Bluetooth adapter, or the Bluetooth service isn't running. Install bluez and run: sudo systemctl enable --now bluetooth"
    }

    Card {
        visible: page.adapter !== null
        SettingRow {
            label: "Bluetooth"
            description: page.adapter ? page.adapter.name : ""
            Toggle {
                checked: page.adapter !== null && page.adapter.enabled
                onToggled: c => page.adapter.enabled = c
            }
        }
        SettingRow {
            visible: page.adapter !== null && page.adapter.enabled
            label: "Find devices"
            description: page.adapter && page.adapter.discovering ? "Searching… put your device in pairing mode." : "Look for nearby devices to pair."
            Btn {
                text: page.adapter && page.adapter.discovering ? "Stop" : "Search"
                icon: "refresh"
                busy: page.adapter !== null && page.adapter.discovering
                onClicked: page.adapter.discovering = !page.adapter.discovering
            }
        }
    }

    Card {
        visible: page.adapter !== null && page.adapter.enabled
        title: "Devices"

        Txt {
            visible: page.devices.length === 0
            text: "No devices yet. Use Search to find one."
            muted: true
            size: 13
        }

        Repeater {
            model: page.devices
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var d: modelData

                Layout.fillWidth: true
                implicitHeight: rowLayout.implicitHeight + 20
                radius: Theme.radiusSmall
                color: Theme.field
                border.width: 1
                border.color: d.connected ? Theme.accent : Theme.line

                RowLayout {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Icon { name: "bluetooth"; color: row.d.connected ? Theme.accent : Theme.muted }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Txt { Layout.fillWidth: true; text: row.d.name || row.d.address; strong: true; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                        Txt {
                            text: (row.d.connected ? "Connected" : row.d.pairing ? "Pairing…" : row.d.paired ? "Paired" : "Not paired")
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
    }
}
