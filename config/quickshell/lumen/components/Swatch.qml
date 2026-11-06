import QtQuick
import qs.services

// Round colour swatch with a selection ring, like the demo's color picker.
Rectangle {
    id: sw

    property color swatch
    property bool selected: false
    signal clicked()

    width: 36
    height: 36
    radius: 18
    color: swatch
    border.width: 2
    border.color: selected ? Theme.panel : Theme.line

    Rectangle {
        anchors.fill: parent
        anchors.margins: -5
        radius: width / 2
        color: "transparent"
        border.width: 3
        border.color: Theme.accent
        visible: sw.selected
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: sw.clicked() }
}
