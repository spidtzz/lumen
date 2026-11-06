import QtQuick
import qs.services
import qs.components

// Tray. Grouped (default): pinned icons stay on the bar and the rest sit
// behind an arrow, like Windows. Ungrouped: every icon on the bar, like
// GNOME and Plasma. Both are set in Settings > Bar.
Grid {
    id: root

    property bool vertical: false
    property var bar   // the Bar window, for popup placement

    readonly property bool grouped: Theme.conf.tray_grouped !== "false"
    readonly property var barItems: grouped ? Tray.items.filter(i => Tray.isPinned(i.id)) : Tray.items
    readonly property var hidden: grouped ? Tray.items.filter(i => !Tray.isPinned(i.id)) : []

    columns: vertical ? 1 : 99
    spacing: 2
    visible: Tray.items.length > 0

    BarButton {
        id: expander
        visible: root.grouped && root.hidden.length > 0
        vertical: root.vertical
        padding: 5
        implicitWidth: 26
        implicitHeight: 26
        open: Panels.popup === "tray" && Panels.popupScreen === root.bar.screen
        onClicked: Panels.togglePopup("tray", root.bar.screen, root.bar.anchorOf(expander))

        Icon {
            name: {
                const e = Theme.barPosition;
                if (e === "bottom") return expander.open ? "chevron-down" : "chevron-up";
                if (e === "left") return expander.open ? "chevron-left" : "chevron-right";
                if (e === "right") return expander.open ? "chevron-right" : "chevron-left";
                return expander.open ? "chevron-up" : "chevron-down";
            }
            size: 15
            color: expander.open ? Theme.accentFg : Theme.ink
        }
    }

    Repeater {
        model: root.barItems
        delegate: TrayIcon {
            required property var modelData
            item: modelData
        }
    }
}
