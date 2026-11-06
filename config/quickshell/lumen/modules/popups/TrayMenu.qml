import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// A tray icon's right-click menu: "Pin to bar" first, then the app's own
// menu (read from the app, submenus open in place).
PopupCard {
    id: menu

    padding: 6
    spacing: 2
    implicitWidth: Math.min(320, Math.max(220, col.implicitWidth + padding * 2))

    readonly property var item: Panels.menuItem
    readonly property bool grouped: Theme.conf.tray_grouped !== "false"
    property var stack: []   // submenu handles, innermost last
    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : (item ? item.menu : null)

    QsMenuOpener {
        id: opener
        menu: menu.current
    }

    ColumnLayout {
        id: col
        Layout.fillWidth: true
        spacing: 2

        // ---- lumen's own options ----
        MenuRow {
            visible: menu.stack.length === 0 && menu.item !== null
            icon: "pin"
            text: !menu.grouped ? "Pin to bar (turn on grouping in Settings)"
                : Tray.isPinned(menu.item ? menu.item.id : "") ? "Unpin from bar" : "Pin to bar"
            enabled: menu.grouped
            onClicked: {
                Tray.setPinned(menu.item.id, !Tray.isPinned(menu.item.id));
                Panels.closePopup();
            }
        }
        MenuRow {
            visible: menu.stack.length > 0
            icon: "chevron-left"
            text: "Back"
            onClicked: menu.stack = menu.stack.slice(0, -1)
        }
        Rectangle {
            visible: entries.count > 0 || menu.stack.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 3
            Layout.bottomMargin: 3
            implicitHeight: 1
            color: Theme.line
        }

        // ---- the app's menu ----
        Repeater {
            id: entries
            model: opener.children ? opener.children.values : []
            delegate: Item {
                id: entry
                required property var modelData
                Layout.fillWidth: true
                implicitWidth: modelData.isSeparator ? 0 : rowItem.implicitWidth
                implicitHeight: modelData.isSeparator ? 7 : rowItem.implicitHeight

                Rectangle {
                    visible: entry.modelData.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 1
                    color: Theme.line
                }
                MenuRow {
                    id: rowItem
                    visible: !entry.modelData.isSeparator
                    width: parent.width
                    text: (entry.modelData.text || "").replace(/_([^_])/g, "$1")
                    checked: entry.modelData.checkState === Qt.Checked
                    submenu: entry.modelData.hasChildren
                    enabled: entry.modelData.enabled
                    onClicked: {
                        if (entry.modelData.hasChildren) {
                            menu.stack = menu.stack.concat([entry.modelData]);
                        } else {
                            entry.modelData.triggered();
                            Panels.closePopup();
                        }
                    }
                }
            }
        }

        Txt {
            visible: entries.count === 0 && menu.stack.length === 0 && !(menu.item && menu.item.hasMenu)
            Layout.margins: 8
            text: "This app has no menu."
            muted: true
            size: 12
        }
    }
}
