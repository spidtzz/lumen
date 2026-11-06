import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services

// One tray icon. Left click opens the app (or its menu if that's all it has),
// right click the app's menu, middle click its secondary action, scroll is
// passed to the app.
Item {
    id: root

    required property var item
    property int size: 18
    signal activated()

    implicitWidth: size + 8
    implicitHeight: size + 8

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: mouse.containsMouse ? Theme.field : "transparent"
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: root.size
        source: Tray.iconFor(root.item)
        asynchronous: true
    }

    function openMenu() {
        const win = QsWindow.window;
        if (!win || !root.item.hasMenu) return;
        const p = root.mapToItem(win.contentItem, 0, root.height + 4);
        root.item.display(win, p.x, p.y);
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => {
            if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && root.item.onlyMenu)) {
                root.openMenu();
            } else if (event.button === Qt.MiddleButton) {
                root.item.secondaryActivate();
            } else {
                root.item.activate();
            }
            root.activated();
        }
        onWheel: event => root.item.scroll(event.angleDelta.y / 120, false)
    }
}
