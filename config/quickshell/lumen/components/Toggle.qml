import QtQuick
import qs.services

// The demo's switch: takes effect immediately.
Rectangle {
    id: sw

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 28
    radius: Theme.r(height / 2)
    opacity: enabled ? 1 : 0.5
    color: checked ? Theme.accent : Theme.field
    border.width: 1
    border.color: checked ? Theme.accent : hover.hovered ? Theme.accent : Theme.line
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }

    // The knob, centred vertically with the same 4px inset on both sides.
    Rectangle {
        width: 20; height: 20; radius: Theme.r(10)
        y: (sw.height - height) / 2
        x: sw.checked ? sw.width - width - 4 : 4
        color: sw.checked ? Theme.accentFg : Theme.ink
        Behavior on x { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeInOut } }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: sw.toggled(!sw.checked) }
    Keys.onSpacePressed: toggled(!checked)
}
