import QtQuick
import qs.services

// Class name of the focused window (e.g. "kitty", "firefox").
Text {
    id: label

    property real maxWidth: 260

    readonly property bool empty: Bspwm.focusedClass === ""
    text: empty ? "Desktop" : Bspwm.focusedClass
    // A fixed slot: a long or short name never changes the layout.
    width: Math.min(Math.round(200 * Theme.fontScale), maxWidth)
    elide: Text.ElideRight
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(15 * Theme.fontScale)
    font.weight: Font.Bold
    color: empty ? Theme.barMuted : Theme.barInk
}
