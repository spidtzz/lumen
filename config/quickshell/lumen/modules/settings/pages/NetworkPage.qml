import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Network: how you're connected now on top, then wired connections, then
// Wi-Fi networks (strongest first) with the password field opening in place.
Page {
    id: page
    title: "Network"
    description: "Wired and Wi-Fi connections."

    property string expanded: ""   // Wi-Fi network showing the password field

    readonly property var wired: Network.devices.filter(d => d.type === "ethernet")
    readonly property var wifiDev: Network.devices.find(d => d.type === "wifi") ?? null
    readonly property var wiredUp: wired.find(d => d.state === "connected") ?? null
    readonly property var activeWifi: Network.networks.find(n => n.active) ?? null
    readonly property var otherNetworks: Network.networks.filter(n => !n.active)
        .slice().sort((a, b) => b.signal - a.signal)

    function stateLabel(s) {
        if (s === "connected") return "Connected";
        if (s.startsWith("connecting")) return "Connecting…";
        if (s === "unavailable") return "Cable unplugged";
        if (s === "unmanaged") return "Not managed";
        return "Disconnected";
    }
    function strength(sig) {
        return sig >= 75 ? "Excellent signal" : sig >= 50 ? "Good signal" : sig >= 25 ? "Fair signal" : "Weak signal";
    }

    Component.onCompleted: { Network.refresh(); Network.scan(); }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: Network.refresh() }

    Card {
        visible: !Network.available
        title: "NetworkManager isn't installed"
        description: "Install networkmanager and enable it: sudo systemctl enable --now NetworkManager"
    }

    // ---- status ----
    Card {
        visible: Network.available
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Rectangle {
                implicitWidth: 56
                implicitHeight: 56
                radius: Theme.r(16)
                color: page.wiredUp || page.activeWifi ? Theme.accent : Theme.field
                Icon {
                    anchors.centerIn: parent
                    name: page.wiredUp ? "ethernet" : "wifi"
                    size: 26
                    color: page.wiredUp || page.activeWifi ? Theme.accentFg : Theme.muted
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Txt {
                    text: page.wiredUp ? "Connected by cable" : page.activeWifi ? "Connected to " + page.activeWifi.ssid : "Not connected"
                    size: 20
                    strong: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
                Txt {
                    text: page.wiredUp ? (page.wiredUp.connection || page.wiredUp.name)
                        : page.activeWifi ? page.strength(page.activeWifi.signal) + (page.activeWifi.secure ? "  ·  secured" : "  ·  open network")
                        : Network.wifiEnabled ? "Pick a network below." : "Wi-Fi is off."
                    muted: true
                }
            }
            Btn {
                visible: page.activeWifi !== null && page.wifiDev !== null
                text: "Disconnect"
                onClicked: Network.disconnectDevice(page.wifiDev.name)
            }
        }
    }

    Card {
        visible: Network.lastError !== ""
        highlight: true
        title: "Couldn't connect"
        description: Network.lastError
    }

    // ---- wired ----
    Card {
        visible: page.wired.length > 0
        title: "Wired"
        Repeater {
            model: page.wired
            delegate: SettingRow {
                required property var modelData
                icon: "ethernet"
                label: modelData.connection !== "" ? modelData.connection : modelData.name
                description: page.stateLabel(modelData.state) + "  ·  " + modelData.name
                Btn {
                    text: modelData.state === "connected" ? "Disconnect" : "Connect"
                    enabled: modelData.state !== "unavailable" && !Network.busy
                    onClicked: modelData.state === "connected"
                        ? Network.disconnectDevice(modelData.name)
                        : Network.connectDevice(modelData.name)
                }
            }
        }
    }

    // ---- Wi-Fi ----
    Card {
        visible: Network.available && page.wifiDev !== null
        title: "Wi-Fi"

        SettingRow {
            icon: "wifi"
            label: "Wi-Fi"
            description: Network.wifiEnabled ? (Network.scanning ? "Looking for networks…" : Network.networks.length + " networks nearby") : "Off"
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
            model: Network.wifiEnabled ? page.otherNetworks : []
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool open: page.expanded === modelData.ssid

                Layout.fillWidth: true
                implicitHeight: col.implicitHeight + 20
                radius: Theme.radiusSmall
                color: open ? Theme.field : hover.hovered ? Qt.rgba(Theme.field.r, Theme.field.g, Theme.field.b, 0.6) : "transparent"
                border.width: open ? 1 : 0
                border.color: Theme.line

                ColumnLayout {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    RowLayout {
                        spacing: 12
                        Icon {
                            name: "wifi"
                            color: Theme.ink
                            opacity: 0.3 + 0.7 * row.modelData.signal / 100
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Txt { Layout.fillWidth: true; text: row.modelData.ssid; strong: true; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                            Txt { text: page.strength(row.modelData.signal) + (row.modelData.secure ? "" : "  ·  open"); size: 12; muted: true }
                        }
                        Icon { visible: row.modelData.secure; name: "lock"; size: 15; color: Theme.muted }
                    }

                    RowLayout {
                        visible: row.open
                        spacing: 8
                        Field {
                            id: pw
                            Layout.fillWidth: true
                            placeholderText: "Password"
                            echoMode: showPw.checked ? TextInput.Normal : TextInput.Password
                            onAccepted: if (text.length >= 8) Network.connect(row.modelData.ssid, text)
                            Keys.onEscapePressed: event => { page.expanded = ""; event.accepted = true; }
                        }
                        Btn {
                            id: showPw
                            property bool checked: false
                            icon: "eye"
                            variant: checked ? "normal" : "ghost"
                            onClicked: checked = !checked
                        }
                        Btn {
                            text: "Connect"
                            variant: "primary"
                            busy: Network.busy
                            enabled: pw.text.length >= 8
                            onClicked: Network.connect(row.modelData.ssid, pw.text)
                        }
                        Btn { text: "Cancel"; variant: "ghost"; onClicked: page.expanded = "" }
                    }
                }

                HoverHandler { id: hover; cursorShape: row.open ? Qt.ArrowCursor : Qt.PointingHandCursor }
                TapHandler {
                    enabled: !row.open
                    onTapped: {
                        // Open networks (and saved ones) connect straight away;
                        // otherwise the password field opens.
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

        SettingRow {
            visible: page.activeWifi !== null
            icon: "trash"
            label: "Forget " + (page.activeWifi ? page.activeWifi.ssid : "")
            description: "Removes its saved password. You'll need it again to reconnect."
            Btn {
                text: "Forget"
                variant: "ghost"
                onClicked: Network.forget(page.activeWifi.ssid)
            }
        }
    }

    Txt {
        visible: Network.available && page.wired.length === 0 && page.wifiDev === null
        text: "No network devices found."
        muted: true
    }
}
