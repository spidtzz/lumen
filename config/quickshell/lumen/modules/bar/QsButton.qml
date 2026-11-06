import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.components

// Status icons (network, volume, notifications); opens Quick Settings.
BarButton {
    id: btn

    property var bar
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var wifi: Network.devices.find(d => d.type === "wifi" && d.state === "connected")
    readonly property var wired: Network.devices.find(d => d.type === "ethernet" && d.state === "connected")
    readonly property color fg: open ? Theme.accentFg : Theme.ink

    open: Panels.popup === "qs" && Panels.popupScreen === bar.screen
    onClicked: Panels.togglePopup("qs", bar.screen, bar.anchorOf(btn))

    PwObjectTracker { objects: btn.sink ? [btn.sink] : [] }

    Grid {
        columns: btn.vertical ? 1 : 3
        spacing: 9

        Icon {
            name: btn.wired ? "ethernet" : "wifi"
            size: 16
            color: btn.fg
            opacity: btn.wifi || btn.wired ? 1 : 0.4
        }
        Icon {
            name: btn.sink && btn.sink.audio && btn.sink.audio.muted ? "volume-x" : "volume"
            size: 16
            color: btn.fg
        }
        Item {
            width: 16; height: 16
            Icon {
                name: Notifs.dnd ? "bell-off" : "bell"
                size: 16
                color: btn.fg
            }
            Rectangle {
                visible: Notifs.list.length > 0 && !Notifs.dnd
                width: 7; height: 7; radius: 4
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: -1
                color: btn.open ? Theme.accentFg : Theme.accent
                border.width: 1
                border.color: btn.open ? Theme.accent : Theme.panel
            }
        }
    }
}
