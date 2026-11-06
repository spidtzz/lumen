import QtQuick
import Quickshell
import qs.services

// Time (and date on hover). Stacked hours/minutes on a vertical bar.
Rectangle {
    id: root

    property bool vertical: false

    implicitWidth: vertical ? 26 : label.implicitWidth + 20
    implicitHeight: vertical ? label.implicitHeight + 14 : 26
    radius: Theme.radiusSmall
    color: hover.hovered ? Theme.field : "transparent"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: label
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: root.vertical ? Qt.formatDateTime(clock.date, "HH\nmm")
            : hover.hovered ? Qt.formatDateTime(clock.date, "ddd d MMM  ·  HH:mm")
            : Qt.formatDateTime(clock.date, "HH:mm")
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.weight: Font.Bold
        color: Theme.ink
    }

    HoverHandler { id: hover }
}
