import QtQuick
import qs.services

// Class name of the focused window (e.g. "kitty", "firefox").
Text {
    id: label

    property real maxWidth: 260

    readonly property bool empty: Bspwm.focusedClass === ""
    text: empty ? "Desktop" : Bspwm.focusedClass
    width: Math.min(implicitWidth, maxWidth)
    elide: Text.ElideRight
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(15 * Theme.fontScale)
    font.weight: Font.Bold
    color: empty ? Theme.muted : Theme.ink
}
