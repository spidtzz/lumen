import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import qs.services
import qs.components

// GNOME-style Quick Settings: you, quick toggles, volume and brightness,
// the power menu, and notifications. Right-click a tile for its settings.
PopupCard {
    id: qs

    implicitWidth: 380

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var wifiDev: Network.devices.find(d => d.type === "wifi") ?? null
    readonly property var wiredDev: Network.devices.find(d => d.type === "ethernet") ?? null
    property string confirm: ""   // "logout" | "restart" | "shutdown"
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btConnected: bt ? bt.devices.values.filter(d => d.connected) : []

    PwObjectTracker { objects: qs.sink ? [qs.sink] : [] }

    function close() { Panels.closePopup(); }
    function run(cmd) { close(); Quickshell.execDetached(cmd); }

    // With the bar at the bottom or on a side, the card is turned upside
    // down: notifications on top (newest at the bottom), then sliders and
    // toggles, and you, Settings and power along the bottom.
    readonly property bool flipped: Theme.barPosition !== "top"
    // Quick settings is built once and kept; this runs each time it opens.
    function opened() {
        confirm = "";
        // after the opening animation, so it can't hold it up
        refreshLater.restart();
    }
    Component.onCompleted: {
        if (!flipped) return;
        const col = header.parent;
        for (const it of [notifHeader, notifEmpty, notifList, divider, media, volumeRow, brightnessRow, toggles, header]) {
            it.parent = null;
            it.parent = col;
        }
    }

    Timer { id: refreshLater; interval: 400; onTriggered: Brightness.refresh() }

    // ---- header: you on the left; Settings and the power menu on the right ----
    RowLayout {
        id: header
        Layout.fillWidth: true
        spacing: 8
        Avatar { size: 40 }

        // Laptops: charge and how long it lasts; click for power settings.
        Rectangle {
            visible: Battery.present
            Layout.leftMargin: 4
            implicitWidth: batRow.implicitWidth + 20
            implicitHeight: 44
            radius: Theme.r(12)
            color: batHover.hovered ? Theme.field : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            RowLayout {
                id: batRow
                anchors.centerIn: parent
                spacing: 10
                BatteryIcon { size: 18 }
                ColumnLayout {
                    spacing: 0
                    Txt {
                        text: Battery.percent + "%"
                        strong: true
                        size: 14
                        font.features: ({ "tnum": 1 })
                    }
                    Txt {
                        text: Battery.estimate
                        muted: true
                        size: 12
                        font.features: ({ "tnum": 1 })
                    }
                }
            }
            HoverHandler { id: batHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Panels.openSettings("performance") }
        }

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
        id: toggles
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
            onRightClicked: Panels.openSettings("network")
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
            icon: "bluetooth"
            label: "Bluetooth"
            enabled: qs.bt !== null
            active: qs.bt !== null && qs.bt.enabled
            status: qs.bt === null ? "No adapter"
                  : !qs.bt.enabled ? "Off"
                  : qs.btConnected.length === 1 ? qs.btConnected[0].name
                  : qs.btConnected.length > 1 ? qs.btConnected.length + " devices"
                  : "On"
            onClicked: qs.bt.enabled = !qs.bt.enabled
            onRightClicked: Panels.openSettings("bluetooth")
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
            icon: "gauge"
            label: "Performance"
            enabled: PowerProfiles.hasPerformanceProfile
            active: PowerProfiles.profile === PowerProfile.Performance
            status: !PowerProfiles.hasPerformanceProfile ? "Not supported here"
                  : active ? "On" : PowerProfiles.profile === PowerProfile.PowerSaver ? "Power saver" : "Balanced"
            onClicked: PowerProfiles.profile = active ? PowerProfile.Balanced : PowerProfile.Performance
            onRightClicked: Panels.openSettings("performance")
        }
        Tile {
            icon: "coffee"
            label: "Keep awake"
            active: Awake.on
            status: Awake.on ? "Screen stays on" : "Off"
            onClicked: Awake.toggle()
            onRightClicked: Panels.openSettings("users")
        }
    }

    // ---- volume ----
    RowLayout {
        id: volumeRow
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

    // ---- brightness (built-in screens only) ----
    RowLayout {
        id: brightnessRow
        visible: Brightness.available
        Layout.fillWidth: true
        spacing: 10
        Item {
            implicitWidth: 38
            implicitHeight: 38
            Icon { anchors.centerIn: parent; name: "brightness"; size: 17 }
        }
        LSlider {
            Layout.fillWidth: true
            from: 0.01; to: 1; stepSize: 0.01
            value: Brightness.value
            onMoved: Brightness.set(value)
        }
        Txt {
            text: Math.round(Brightness.value * 100) + "%"
            muted: true
            size: 12
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }

    // ---- media (Settings > Bar > Quick settings) ----
    MediaCard { id: media }

    Rectangle { id: divider; Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }

    // ---- notifications ----
    RowLayout {
        id: notifHeader
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
        id: notifEmpty
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
        id: notifList
        visible: Notifs.list.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(notifCol.implicitHeight, 320)
        contentHeight: notifCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        // Flipped: start scrolled to the newest (bottom).
        onContentHeightChanged: if (qs.flipped) contentY = Math.max(0, contentHeight - height)

        ColumnLayout {
            id: notifCol
            width: parent.width
            spacing: 8
            Repeater {
                // Flipped: oldest on top, newest nearest the toggles.
                model: qs.flipped ? Notifs.list.slice().reverse() : Notifs.list
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
        // Under the power button, or above it when the card is flipped.
        y: qs.flipped ? qs.padding + header.y - height - 6 : qs.padding + 46
        radius: Theme.r(12)
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
            MenuRow { icon: "lock"; text: "Lock"; onClicked: qs.run(["lumen-lock"]) }
            // Log out, restart and shut down ask in the session menu (super + p).
            MenuRow { icon: "log-out"; text: "Log out\u2026"; onClicked: Panels.openSession("logout") }
            MenuRow { icon: "moon"; text: "Suspend"; onClicked: qs.run(["systemctl", "suspend"]) }
            MenuRow { icon: "restart"; text: "Restart\u2026"; onClicked: Panels.openSession("restart") }
            MenuRow { icon: "power"; text: "Shut down\u2026"; onClicked: Panels.openSession("shutdown") }
        }
    }
}
