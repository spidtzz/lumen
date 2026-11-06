import QtQuick
import qs.services

// Text in the shell's font. `size` is in pixels at the default font size and
// scales with the font size setting.
Text {
    property real size: 14
    property bool muted: false
    property bool strong: false

    font.family: Theme.fontFamily
    font.pixelSize: Math.round(size * Theme.fontScale)
    font.weight: strong ? Font.Bold : Font.Medium
    color: muted ? Theme.muted : Theme.ink
    wrapMode: Text.WordWrap
}
