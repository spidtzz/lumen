import QtQuick
import qs.services
import qs.components

// The lumen logo in a circle; opens the app launcher.
Rectangle {
    id: btn

    implicitWidth: 26
    implicitHeight: 26
    radius: 13
    color: Panels.launcherOpen || hover.hovered ? Theme.accent : Theme.field
    border.width: 1
    border.color: Panels.launcherOpen || hover.hovered ? Theme.accent : Theme.line
    scale: tap.pressed ? 0.92 : 1
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: 80 } }

    Icon {
        anchors.centerIn: parent
        name: "lumen"
        size: 18
        stroke: 2.2
        color: Panels.launcherOpen || hover.hovered ? Theme.accentFg : Theme.accent
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: Panels.toggleLauncher() }
}
