import QtQuick
import QtQuick.Controls.Basic
import qs.services

// Slider in the demo's style. Use onMoved for live updates and
// onCommitted for saving when the drag ends.
Slider {
    id: s

    signal committed(real value)
    onPressedChanged: if (!pressed) committed(value)

    implicitWidth: 260
    implicitHeight: 28
    live: true

    background: Rectangle {
        x: s.leftPadding
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: s.availableWidth
        height: 8
        radius: 4
        color: Theme.field
        border.width: 1
        border.color: Theme.line

        Rectangle {
            width: s.visualPosition * parent.width
            height: parent.height
            radius: 4
            color: Theme.accent
        }
    }

    handle: Rectangle {
        x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: 20
        height: 20
        radius: 10
        color: Theme.panel
        border.width: 3
        border.color: Theme.accent
        scale: s.pressed ? 1.1 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
    }
}
