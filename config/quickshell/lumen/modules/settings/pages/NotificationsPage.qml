import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

Page {
    id: page
    title: "Notifications"
    description: "Where new notifications appear, and Do Not Disturb."

    readonly property string position: Theme.conf.notif_position || "top-right"

    Card {
        title: "Position"
        description: "Pick where pop-ups appear. They always stay clear of the bar."

        // A small screen with six spots to choose from.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 360
            Layout.preferredHeight: 220
            radius: Theme.radiusSmall
            color: Theme.bg
            border.width: 1
            border.color: Theme.line

            // the bar, on its current edge
            Rectangle {
                readonly property bool vertical: Theme.barPosition === "left" || Theme.barPosition === "right"
                width: vertical ? 10 : parent.width - 16
                height: vertical ? parent.height - 16 : 10
                x: Theme.barPosition === "right" ? parent.width - width - 6 : vertical ? 6 : 8
                y: Theme.barPosition === "bottom" ? parent.height - height - 6 : vertical ? 8 : 6
                radius: 5
                color: Theme.panel
                border.width: 1
                border.color: Theme.line
            }

            Repeater {
                model: ["top-left", "top-center", "top-right", "bottom-left", "bottom-center", "bottom-right"]
                delegate: Rectangle {
                    id: spot
                    required property string modelData
                    readonly property var p: modelData.split("-")
                    readonly property bool selected: page.position === modelData

                    width: 96
                    height: 34
                    radius: 8
                    x: p[1] === "left" ? 26 : p[1] === "center" ? (parent.width - width) / 2 : parent.width - width - 26
                    y: p[0] === "top" ? 28 : parent.height - height - 28
                    color: selected ? Theme.accent : spotHover.hovered ? Theme.field : Theme.panel
                    border.width: 1
                    border.color: selected || spotHover.hovered ? Theme.accent : Theme.line

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Rectangle { width: 54; height: 4; radius: 2; color: spot.selected ? Theme.accentFg : Theme.ink; opacity: 0.8 }
                        Rectangle { width: 36; height: 4; radius: 2; color: spot.selected ? Theme.accentFg : Theme.muted; opacity: 0.8 }
                    }
                    HoverHandler { id: spotHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Theme.setValue("notif_position", spot.modelData) }
                }
            }
        }

        RowLayout {
            spacing: 8
            Btn {
                text: "Send a test notification"
                icon: "bell"
                onClicked: Quickshell.execDetached(["notify-send", "-a", "lumen", "Test notification", "This is where notifications appear."])
            }
            Txt { text: "Needs libnotify (notify-send)."; size: 12; muted: true }
        }
    }

    Card {
        title: "Do Not Disturb"
        SettingRow {
            label: "Do Not Disturb"
            description: "Hide pop-ups (critical ones still show). Notifications still collect in Quick Settings."
            Toggle {
                checked: Notifs.dnd
                onToggled: c => Notifs.dnd = c
            }
        }
        SettingRow {
            label: "History"
            description: Notifs.list.length === 0 ? "No notifications." : Notifs.list.length + (Notifs.list.length === 1 ? " notification" : " notifications") + " in Quick Settings."
            Btn {
                text: "Clear all"
                variant: "ghost"
                enabled: Notifs.list.length > 0
                onClicked: Notifs.clearAll()
            }
        }
    }
}
