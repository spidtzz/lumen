import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Page {
    id: page
    title: "Network"
    description: "Wired and Wi-Fi connections (NetworkManager)."

    property string expanded: ""   // Wi-Fi network showing the password field

    readonly property var wired: Network.devices.filter(d => d.type === "ethernet")
    readonly property var wifiDev: Network.devices.find(d => d.type === "wifi") ?? null

    function stateLabel(s) {
        if (s === "connected") return "Connected";
        if (s.startsWith("connecting")) return "Connecting…";
        if (s === "unavailable") return "Cable unplugged";
        if (s === "unmanaged") return "Not managed";
        return "Disconnected";
    }

    Component.onCompleted: { Network.refresh(); Network.scan(); }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: Network.refresh() }

    Card {
        visible: !Network.available
        title: "NetworkManager isn't installed"
        description: "Install networkmanager and enable it: sudo systemctl enable --now NetworkManager"
    }

    Card {
        visible: Network.lastError !== ""
        title: "Couldn't connect"
        description: Network.lastError
    }

    Repeater {
        model: page.wired
        delegate: Card {
            id: wc
            required property var modelData
            title: "Wired"
            SettingRow {
                label: wc.modelData.connection !== "" ? wc.modelData.connection : wc.modelData.name
                description: page.stateLabel(wc.modelData.state) + "  ·  " + wc.modelData.name
                Icon { name: "ethernet"; color: wc.modelData.state === "connected" ? Theme.accent : Theme.muted }
                Btn {
                    text: wc.modelData.state === "connected" ? "Disconnect" : "Connect"
                    enabled: wc.modelData.state !== "unavailable" && !Network.busy
                    onClicked: wc.modelData.state === "connected"
                        ? Network.disconnectDevice(wc.modelData.name)
                        : Network.connectDevice(wc.modelData.name)
                }
            }
        }
    }

    Card {
        visible: Network.available && page.wifiDev !== null
        title: "Wi-Fi"

        SettingRow {
            label: "Wi-Fi"
            description: page.wifiDev ? page.stateLabel(page.wifiDev.state) + (page.wifiDev.connection ? " to " + page.wifiDev.connection : "") : ""
            Btn {
                icon: "refresh"
                variant: "ghost"
                busy: Network.scanning
                enabled: Network.wifiEnabled
                onClicked: Network.scan()
            }
            Toggle {
                checked: Network.wifiEnabled
                onToggled: c => Network.setWifi(c)
            }
        }

        Repeater {
            model: Network.wifiEnabled ? Network.networks : []
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool open: page.expanded === modelData.ssid

                Layout.fillWidth: true
                implicitHeight: col.implicitHeight + 16
                radius: Theme.radiusSmall
                color: hover.hovered || open ? Theme.field : "transparent"

                ColumnLayout {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    RowLayout {
                        spacing: 12
                        Icon {
                            name: "wifi"
                            color: row.modelData.active ? Theme.accent : Theme.ink
                            opacity: 0.35 + 0.65 * row.modelData.signal / 100
                        }
                        Txt {
                            Layout.fillWidth: true
                            text: row.modelData.ssid
                            strong: row.modelData.active
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                        Txt { visible: row.modelData.active; text: "Connected"; size: 12; color: Theme.accent; strong: true }
                        Icon { visible: row.modelData.secure; name: "lock"; size: 15; color: Theme.muted }
                    }

                    RowLayout {
                        visible: row.open
                        spacing: 8
                        Field {
                            id: pw
                            Layout.fillWidth: true
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                            onAccepted: Network.connect(row.modelData.ssid, text)
                        }
                        Btn {
                            text: "Connect"
                            variant: "primary"
                            busy: Network.busy
                            enabled: pw.text.length >= 8
                            onClicked: Network.connect(row.modelData.ssid, pw.text)
                        }
                    }
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    enabled: !row.open && !row.modelData.active
                    onTapped: {
                        // Open networks (and saved ones) connect straight away;
                        // if NetworkManager needs a password, the field appears.
                        if (row.modelData.secure) page.expanded = row.modelData.ssid;
                        else Network.connect(row.modelData.ssid, "");
                    }
                }
            }
        }

        Txt {
            visible: Network.wifiEnabled && Network.networks.length === 0
            text: Network.scanning ? "Looking for networks…" : "No networks found."
            muted: true
        }
    }

    Txt {
        visible: Network.available && page.wired.length === 0 && page.wifiDev === null
        text: "No network devices found."
        muted: true
    }
}
