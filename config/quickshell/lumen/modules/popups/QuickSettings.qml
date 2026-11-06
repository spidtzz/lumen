import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.components

// GNOME-style Quick Settings: you, quick toggles, volume, session buttons
// and notifications.
PopupCard {
    id: qs

    implicitWidth: 380

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var wifiDev: Network.devices.find(d => d.type === "wifi") ?? null
    readonly property var wiredDev: Network.devices.find(d => d.type === "ethernet") ?? null
    property string confirm: ""   // "logout" | "restart" | "shutdown"

    PwObjectTracker { objects: qs.sink ? [qs.sink] : [] }

    function close() { Panels.closePopup(); }
    function run(cmd) { close(); Quickshell.execDetached(cmd); }

    // ---- header: you, Settings, lock, power ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Avatar { size: 40 }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt { text: Theme.userName; strong: true; size: 15 }
            Txt { text: "Quick settings"; muted: true; size: 12 }
        }
        Btn { icon: "settings"; variant: "ghost"; onClicked: Panels.openSettings("appearance") }
        Btn { icon: "lock"; variant: "ghost"; onClicked: qs.run(["lumen-lock"]) }
        Btn {
            icon: "power"
            variant: qs.confirm === "" ? "ghost" : "normal"
            onClicked: qs.confirm = qs.confirm === "" ? "menu" : ""
        }
    }

    // ---- session ----
    ColumnLayout {
        visible: qs.confirm !== ""
        Layout.fillWidth: true
        spacing: 8

        GridLayout {
            visible: qs.confirm === "menu"
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 6
            Repeater {
                model: [
                    { id: "lock", label: "Lock", icon: "lock" },
                    { id: "logout", label: "Log out", icon: "log-out" },
                    { id: "restart", label: "Restart", icon: "restart" },
                    { id: "shutdown", label: "Shut down", icon: "power" }
                ]
                delegate: Rectangle {
                    id: sb
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 12
                    color: sbHover.hovered ? Theme.accent : Theme.field
                    border.width: 1
                    border.color: sbHover.hovered ? Theme.accent : Theme.line
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Icon { Layout.alignment: Qt.AlignHCenter; name: sb.modelData.icon; size: 18; color: sbHover.hovered ? Theme.accentFg : Theme.ink }
                        Txt { Layout.alignment: Qt.AlignHCenter; text: sb.modelData.label; size: 11; strong: true; color: sbHover.hovered ? Theme.accentFg : Theme.ink }
                    }
                    HoverHandler { id: sbHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: sb.modelData.id === "lock" ? qs.run(["lumen-lock"]) : qs.confirm = sb.modelData.id
                    }
                }
            }
        }

        Rectangle {
            visible: qs.confirm !== "menu"
            Layout.fillWidth: true
            implicitHeight: confirmRow.implicitHeight + 24
            radius: 12
            color: Theme.field
            border.width: 1
            border.color: Theme.line
            RowLayout {
                id: confirmRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                Txt {
                    Layout.fillWidth: true
                    text: qs.confirm === "logout" ? "Log out now?" : qs.confirm === "restart" ? "Restart now?" : "Shut down now?"
                    strong: true
                }
                Btn { text: "Cancel"; variant: "ghost"; onClicked: qs.confirm = "menu" }
                Btn {
                    text: qs.confirm === "logout" ? "Log out" : qs.confirm === "restart" ? "Restart" : "Shut down"
                    variant: "danger"
                    onClicked: qs.run(qs.confirm === "logout" ? ["bspc", "quit"]
                                    : qs.confirm === "restart" ? ["systemctl", "reboot"]
                                    : ["systemctl", "poweroff"])
                }
            }
        }
    }

    // ---- toggles ----
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        Tile {
            visible: qs.wifiDev !== null
            icon: "wifi"
            label: "Wi-Fi"
            active: Network.wifiEnabled
            status: !Network.wifiEnabled ? "Off" : qs.wifiDev && qs.wifiDev.connection ? qs.wifiDev.connection : "Not connected"
            onClicked: Network.setWifi(!Network.wifiEnabled)
        }
        Tile {
            visible: qs.wifiDev === null
            icon: "ethernet"
            label: "Wired"
            active: qs.wiredDev !== null && qs.wiredDev.state === "connected"
            status: active ? "Connected" : "Disconnected"
            onClicked: Panels.openSettings("network")
        }
        Tile {
            icon: Theme.dark ? "moon" : "sun"
            label: "Dark style"
            active: Theme.dark
            status: Theme.dark ? "On" : "Off"
            onClicked: Theme.setValue("mode", Theme.dark ? "light" : "dark")
        }
        Tile {
            icon: Notifs.dnd ? "bell-off" : "bell"
            label: "Do not disturb"
            active: Notifs.dnd
            status: Notifs.dnd ? "Notifications hidden" : "Off"
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        Tile {
            readonly property bool fxOn: Theme.conf.compositor !== "false"
            icon: "droplet"
            label: "Effects"
            active: fxOn
            status: fxOn ? "Shadows and fades" : "Off"
            onClicked: Theme.setValue("compositor", !fxOn)
        }
    }

    // ---- volume ----
    RowLayout {
        visible: qs.sink !== null && qs.sink.audio !== null
        Layout.fillWidth: true
        spacing: 10
        Btn {
            readonly property bool muted: qs.sink && qs.sink.audio ? qs.sink.audio.muted : false
            icon: muted ? "volume-x" : "volume"
            variant: "ghost"
            onClicked: qs.sink.audio.muted = !muted
        }
        LSlider {
            Layout.fillWidth: true
            from: 0; to: 1; stepSize: 0.01
            value: qs.sink && qs.sink.audio ? qs.sink.audio.volume : 0
            onMoved: qs.sink.audio.volume = value
        }
        Txt {
            text: Math.round((qs.sink && qs.sink.audio ? qs.sink.audio.volume : 0) * 100) + "%"
            muted: true
            size: 12
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }

    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }

    // ---- notifications ----
    RowLayout {
        Layout.fillWidth: true
        Txt { Layout.fillWidth: true; text: "Notifications"; strong: true }
        Btn {
            visible: Notifs.list.length > 0
            text: "Clear all"
            variant: "ghost"
            implicitHeight: 30
            onClicked: Notifs.clearAll()
        }
    }

    ColumnLayout {
        visible: Notifs.list.length === 0
        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        spacing: 6
        Icon { Layout.alignment: Qt.AlignHCenter; name: "bell"; size: 26; color: Theme.muted; opacity: 0.6 }
        Txt { Layout.alignment: Qt.AlignHCenter; text: "No notifications"; muted: true; size: 13 }
    }

    Flickable {
        visible: Notifs.list.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(notifCol.implicitHeight, 320)
        contentHeight: notifCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: notifCol
            width: parent.width
            spacing: 8
            Repeater {
                model: Notifs.list
                delegate: NotificationCard {
                    required property var modelData
                    notification: modelData
                    onDismissed: modelData.dismiss()
                }
            }
        }
    }
}
