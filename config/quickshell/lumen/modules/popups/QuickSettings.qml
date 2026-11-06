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

    // ---- header: you on the left; Settings and the power menu on the right ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Avatar { size: 40 }
        Item { Layout.fillWidth: true }
        Btn { icon: "settings"; variant: "ghost"; onClicked: Panels.openSettings("appearance") }
        Btn {
            id: powerBtn
            icon: "power"
            variant: qs.confirm !== "" ? "normal" : "ghost"
            onClicked: qs.confirm = qs.confirm === "" ? "menu" : ""
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

    Item {
        visible: Notifs.list.length === 0
        Layout.fillWidth: true
        implicitHeight: emptyCol.implicitHeight + 16
        Column {
            id: emptyCol
            anchors.centerIn: parent
            spacing: 6
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bell"; size: 26; color: Theme.muted; opacity: 0.6 }
            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "No notifications"; muted: true; size: 13; wrapMode: Text.NoWrap }
        }
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

    // ---- power menu: drops down under the power button ----
    Rectangle {
        id: powerMenu
        parent: qs
        visible: qs.confirm !== ""
        z: 10
        width: 220
        height: powerCol.implicitHeight + 12
        x: qs.width - width - qs.padding
        y: qs.padding + 46
        radius: 12
        color: Theme.panel
        border.width: 1
        border.color: Theme.line

        // soft shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.margins: -1
            anchors.topMargin: 3
            radius: parent.radius
            color: "#000000"
            opacity: 0.18
        }

        ColumnLayout {
            id: powerCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2

            // the menu
            MenuRow { visible: qs.confirm === "menu"; icon: "lock"; text: "Lock"; onClicked: qs.run(["lumen-lock"]) }
            MenuRow { visible: qs.confirm === "menu"; icon: "log-out"; text: "Log out\u2026"; onClicked: qs.confirm = "logout" }
            MenuRow { visible: qs.confirm === "menu"; icon: "restart"; text: "Restart\u2026"; onClicked: qs.confirm = "restart" }
            MenuRow { visible: qs.confirm === "menu"; icon: "power"; text: "Shut down\u2026"; onClicked: qs.confirm = "shutdown" }

            // confirmation
            Txt {
                visible: qs.confirm !== "menu"
                Layout.margins: 8
                Layout.fillWidth: true
                text: qs.confirm === "logout" ? "Log out now?" : qs.confirm === "restart" ? "Restart now?" : "Shut down now?"
                strong: true
            }
            RowLayout {
                visible: qs.confirm !== "menu"
                Layout.fillWidth: true
                Layout.margins: 4
                spacing: 6
                Btn { Layout.fillWidth: true; text: "Cancel"; variant: "ghost"; onClicked: qs.confirm = "menu" }
                Btn {
                    Layout.fillWidth: true
                    text: qs.confirm === "logout" ? "Log out" : qs.confirm === "restart" ? "Restart" : "Shut down"
                    variant: "danger"
                    onClicked: qs.run(qs.confirm === "logout" ? ["bspc", "quit"]
                                    : qs.confirm === "restart" ? ["systemctl", "reboot"]
                                    : ["systemctl", "poweroff"])
                }
            }
        }
    }
}
