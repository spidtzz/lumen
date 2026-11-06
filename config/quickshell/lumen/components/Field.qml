import QtQuick
import QtQuick.Controls.Basic
import qs.services

// Text field in the demo's style.
TextField {
    id: f

    property bool invalid: false

    implicitHeight: 40
    leftPadding: 12
    rightPadding: 12
    color: Theme.ink
    placeholderTextColor: Theme.muted
    selectionColor: Theme.accent
    selectedTextColor: Theme.accentFg
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(14 * Theme.fontScale)

    background: Rectangle {
        radius: Theme.radiusSmall
        color: Theme.field
        border.width: f.activeFocus ? 2 : 1
        border.color: f.invalid ? Theme.danger : f.activeFocus ? Theme.accent : Theme.line
    }
}
