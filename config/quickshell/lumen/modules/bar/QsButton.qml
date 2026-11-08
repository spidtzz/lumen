import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.components

// Status icons (network, volume, notifications, and the battery on laptops);
// opens Quick Settings.
BarButton {
    id: btn

    property var bar
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var wifi: Network.devices.find(d => d.type === "wifi" && d.state === "connected")
    readonly property var wired: Network.devices.find(d => d.type === "ethernet" && d.state === "connected")
    readonly property color fg: open ? Theme.barAccentFg : Theme.barInk

    open: Panels.popup === "qs" && Panels.popupScreen === bar.screen
    onClicked: Panels.togglePopup("qs", bar.screen, bar.anchorOf(btn))

    PwObjectTracker { objects: btn.sink ? [btn.sink] : [] }

    Grid {
        columns: btn.vertical ? 1 : (Battery.present ? 4 : 3)
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
                width: 7; height: 7; radius: Theme.r(4)
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: -1
                color: btn.open ? Theme.barAccentFg : Theme.barAccent
                border.width: 1
                border.color: btn.open ? Theme.barAccent : Theme.barBg
            }
        }
        // battery: icon and percentage (under the icon on a side bar)
        Grid {
            visible: Battery.present
            columns: btn.vertical ? 1 : 2
            spacing: btn.vertical ? 2 : 5
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            BatteryIcon { size: 15; color: btn.fg }
            Txt {
                id: pct
                // fixed width, so the bar doesn't shift as the number changes
                width: btn.vertical ? implicitWidth : widest.width
                horizontalAlignment: Text.AlignLeft
                text: Battery.percent + (btn.vertical ? "" : "%")
                size: btn.vertical ? 10 : 12
                strong: true
                color: btn.fg
                font.features: ({ "tnum": 1 })
                TextMetrics { id: widest; font: pct.font; text: "100%" }
            }
        }
    }
}
