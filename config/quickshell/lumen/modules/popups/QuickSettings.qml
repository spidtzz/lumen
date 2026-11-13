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
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property bool showMic: Theme.conf.qs_mic === "true"
    property string deviceList: ""   // "sink" | "source": the device menu that's open
    property real deviceBelow: 0     // the menu's button: its bottom and top edge
    property real deviceAbove: 0
    function openDevices(kind, btn) {
        if (deviceList === kind) { deviceList = ""; return; }
        confirm = "";
        deviceBelow = btn.mapToItem(qs, 0, btn.height).y;
        deviceAbove = btn.mapToItem(qs, 0, 0).y;
        deviceList = kind;
    }
    function nodeLabel(n) { return n.description || n.nickname || n.name; }
    readonly property var wifiDev: Network.devices.find(d => d.type === "wifi") ?? null
    readonly property var wiredDev: Network.devices.find(d => d.type === "ethernet") ?? null
    property string confirm: ""   // "logout" | "restart" | "shutdown"
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btConnected: bt ? bt.devices.values.filter(d => d.connected) : []

    PwObjectTracker { objects: [qs.sink, qs.source].filter(n => n) }

    function close() { Panels.closePopup(); }
    function run(cmd) { close(); Quickshell.execDetached(cmd); }

    // With the bar at the bottom or on a side, the card is turned upside
    // down: notifications on top (newest at the bottom), then sliders and
    // toggles, and you, Settings and power along the bottom.
    readonly property bool flipped: Theme.barPosition !== "top"
    // Quick settings is built once and kept; this runs each time it opens.
    function opened() {
        confirm = "";
        deviceList = "";
        // after the opening animation, so it can't hold it up
        refreshLater.restart();
    }
    Component.onCompleted: {
        if (!flipped) return;
        const col = header.parent;
        for (const it of [notifHeader, notifEmpty, notifList, divider, media, volumeRow, micRow, brightnessRow, toggles, header]) {
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
            onClicked: { qs.deviceList = ""; qs.confirm = qs.confirm === "" ? "menu" : ""; }
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
        // Power mode: each click goes on to the next, Power saver ->
        // Balanced -> Performance -> Power saver (no Performance where the
        // hardware has none).
        Tile {
            readonly property var order: PowerProfiles.hasPerformanceProfile
                ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                : [PowerProfile.PowerSaver, PowerProfile.Balanced]
            readonly property int mode: PowerProfiles.profile
            icon: mode === PowerProfile.PowerSaver ? "leaf" : mode === PowerProfile.Performance ? "zap" : "gauge"
            label: "Power mode"
            active: mode !== PowerProfile.Balanced
            status: mode === PowerProfile.PowerSaver ? "Power saver" : mode === PowerProfile.Performance ? "Performance" : "Balanced"
            onClicked: PowerProfiles.profile = order[(Math.max(0, order.indexOf(mode)) + 1) % order.length]
            onRightClicked: Panels.openSettings("performance")
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
        Btn {
            id: sinkBtn
            icon: "chevron-down"
            variant: qs.deviceList === "sink" ? "normal" : "ghost"
            implicitWidth: 32
            onClicked: qs.openDevices("sink", sinkBtn)
        }
    }

    // ---- microphone (Settings > Bar > Quick settings) ----
    RowLayout {
        id: micRow
        visible: qs.showMic && qs.source !== null && qs.source.audio !== null
        Layout.fillWidth: true
        spacing: 10
        Btn {
            readonly property bool muted: qs.source && qs.source.audio ? qs.source.audio.muted : false
            icon: muted ? "mic-off" : "mic"
            variant: "ghost"
            onClicked: qs.source.audio.muted = !muted
        }
        LSlider {
            Layout.fillWidth: true
            from: 0; to: 1; stepSize: 0.01
            value: qs.source && qs.source.audio ? qs.source.audio.volume : 0
            onMoved: qs.source.audio.volume = value
        }
        Txt {
            text: Math.round((qs.source && qs.source.audio ? qs.source.audio.volume : 0) * 100) + "%"
            muted: true
            size: 12
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
        Btn {
            id: sourceBtn
            icon: "chevron-down"
            variant: qs.deviceList === "source" ? "normal" : "ghost"
            implicitWidth: 32
            onClicked: qs.openDevices("source", sourceBtn)
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
        Item { implicitWidth: 32 }   // lines up with the device buttons above
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

    // ---- sound device menu: drops down under the arrow next to a slider ----
    // A click anywhere else in the card closes it.
    MouseArea {
        parent: qs
        visible: qs.deviceList !== ""
        z: 9
        anchors.fill: parent
        onClicked: qs.deviceList = ""
    }
    Rectangle {
        id: deviceMenu
        parent: qs
        readonly property bool isSink: qs.deviceList === "sink"
        readonly property var nodes: isSink ? qs.sinks : qs.sources
        readonly property var current: isSink ? qs.sink : qs.source
        visible: qs.deviceList !== ""
        z: 10
        width: Math.min(300, qs.width - 2 * qs.padding)
        height: Math.min(deviceCol.implicitHeight + 12, qs.height - 2 * qs.padding)
        x: qs.width - width - qs.padding
        // Below the arrow, or above it when there's no room below.
        y: qs.deviceBelow + 6 + height <= qs.height - qs.padding
            ? qs.deviceBelow + 6
            : Math.max(qs.padding, qs.deviceAbove - 6 - height)
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

        Flickable {
            anchors.fill: parent
            anchors.margins: 6
            contentHeight: deviceCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: deviceCol
                width: parent.width
                spacing: 2
                Txt {
                    text: deviceMenu.isSink ? "Sound output" : "Microphone"
                    muted: true
                    size: 12
                    Layout.leftMargin: 11
                    Layout.topMargin: 4
                    Layout.bottomMargin: 2
                }
                Repeater {
                    model: deviceMenu.nodes
                    delegate: MenuRow {
                        required property var modelData
                        icon: deviceMenu.isSink ? "volume" : "mic"
                        text: qs.nodeLabel(modelData)
                        checked: deviceMenu.current !== null && modelData.id === deviceMenu.current.id
                        onClicked: {
                            if (deviceMenu.isSink) Pipewire.preferredDefaultAudioSink = modelData;
                            else Pipewire.preferredDefaultAudioSource = modelData;
                            qs.deviceList = "";
                        }
                    }
                }
                Txt {
                    visible: deviceMenu.nodes.length === 0
                    text: "No devices"
                    muted: true
                    size: 13
                    Layout.leftMargin: 11
                }
            }
        }
    }
}
