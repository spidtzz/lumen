import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services

// One tray icon. Left click opens the app (or its menu if that's all it has),
// right click opens lumen's menu for it (Pin to bar + the app's own menu),
// middle click its secondary action, scroll is passed to the app.
Item {
    id: root

    required property var item
    property int size: 18
    property var bar: null   // set for icons on the bar; null inside the tray popup
    signal activated()

    implicitWidth: size + 8
    implicitHeight: size + 8

    Rectangle {
        anchors.fill: parent
        radius: Theme.r(8)
        color: mouse.containsMouse ? Theme.field : "transparent"
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: root.size
        source: Tray.iconFor(root.item)
        asynchronous: true
    }

    function openMenu() {
        if (root.bar)
            Panels.openTrayMenu(root.item, root.bar.screen, root.bar.anchorOf(root));
        else
            Panels.openTrayMenu(root.item, Panels.popupScreen, null);
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
                return;
            }
            if (event.button === Qt.MiddleButton)
                root.item.secondaryActivate();
            else
                root.item.activate();
            root.activated();
        }
        onWheel: event => root.item.scroll(event.angleDelta.y / 120, false)
    }
}
