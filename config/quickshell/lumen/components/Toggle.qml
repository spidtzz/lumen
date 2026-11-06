import QtQuick
import qs.services

// The demo's switch: takes effect immediately.
Rectangle {
    id: sw

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 28
    radius: height / 2
    opacity: enabled ? 1 : 0.5
    color: checked ? Theme.accent : Theme.field
    border.width: 1
    border.color: checked ? Theme.accent : hover.hovered ? Theme.accent : Theme.line
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Rectangle {
        width: 20; height: 20; radius: 10
        y: 3
        x: sw.checked ? sw.width - width - 4 : 3
        color: sw.checked ? Theme.accentFg : Theme.ink
        Behavior on x { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: sw.toggled(!sw.checked) }
    Keys.onSpacePressed: toggled(!checked)
}
