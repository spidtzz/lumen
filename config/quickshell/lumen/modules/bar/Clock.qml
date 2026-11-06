import QtQuick
import Quickshell
import qs.services
import "../../components/Jalali.js" as Jalali

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
        readonly property string time: Qt.formatDateTime(clock.date, Theme.clock24h ? "HH:mm" : "h:mm AP")
        readonly property string date: Theme.shamsiDate ? Jalali.format(clock.date, true)
                                                        : Qt.formatDateTime(clock.date, "ddd d MMM")
        text: root.vertical ? Qt.formatDateTime(clock.date, Theme.clock24h ? "HH\nmm" : "hh\nmm")
            : hover.hovered ? date + "  ·  " + time
            : time
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(14 * Theme.fontScale)
        font.weight: Font.Bold
        color: Theme.ink
    }

    HoverHandler { id: hover }
}
