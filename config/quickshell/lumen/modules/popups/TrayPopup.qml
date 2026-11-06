import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// The tray icons that aren't pinned to the bar (grouped mode).
PopupCard {
    id: root

    padding: 8
    spacing: 6

    readonly property var hidden: Tray.items.filter(i => !Tray.isPinned(i.id))
    implicitWidth: Math.max(grid.implicitWidth + padding * 2, 64)

    GridLayout {
        id: grid
        columns: Math.min(5, Math.max(1, root.hidden.length))
        rowSpacing: 2
        columnSpacing: 2
        Repeater {
            model: root.hidden
            delegate: TrayIcon {
                required property var modelData
                item: modelData
                size: 20
                onActivated: Panels.closePopup()
            }
        }
    }

    Txt {
        Layout.fillWidth: true
        Layout.maximumWidth: 200
        text: "Pin icons to the bar in Settings › Bar"
        size: 11
        muted: true
        visible: root.hidden.length > 0
    }
}
