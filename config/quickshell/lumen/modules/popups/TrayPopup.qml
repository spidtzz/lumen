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
    implicitWidth: grid.implicitWidth + padding * 2

    GridLayout {
        id: grid
        Layout.alignment: Qt.AlignHCenter
        columns: Math.min(4, Math.max(1, root.hidden.length))
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

}
