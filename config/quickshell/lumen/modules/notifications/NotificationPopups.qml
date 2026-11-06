import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.services
import qs.components

// New notifications in the corner next to the bar's Quick Settings button.
// They hide after a few seconds (hovering keeps them) and stay in Quick
// Settings until dismissed. Do Not Disturb hides all but critical ones.
PanelWindow {
    id: win

    screen: Panels.focusedScreen()
    visible: Notifs.popups.length > 0

    readonly property string edge: Theme.barPosition
    anchors {
        top: win.edge !== "bottom"
        bottom: win.edge === "bottom"
        right: true
    }
    margins {
        top: win.edge === "top" ? Theme.barThickness + 6 : Theme.gap
        bottom: win.edge === "bottom" ? Theme.barThickness + 6 : Theme.gap
        right: win.edge === "right" ? Theme.barThickness + 6 : Theme.gap
    }
    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    ColumnLayout {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups
            delegate: NotificationCard {
                id: card
                required property var modelData
                notification: modelData
                popup: true
                onDismissed: modelData.dismiss()

                Timer {
                    running: !card.critical && !card.hovered
                    interval: card.n && card.n.expireTimeout > 0 ? card.n.expireTimeout : 5000
                    onTriggered: Notifs.dismissPopup(card.modelData)
                }
            }
        }
    }
}
