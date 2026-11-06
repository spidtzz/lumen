import QtQuick
import Quickshell
import qs.services
import "../../components/Jalali.js" as Jalali

// Date and time. Click for the calendar.
BarButton {
    id: btn

    property var bar

    open: Panels.popup === "calendar" && Panels.popupScreen === bar.screen
    onClicked: Panels.togglePopup("calendar", bar.screen, bar.anchorOf(btn))

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Text {
        readonly property string time: Qt.formatDateTime(clock.date, Theme.clock24h ? "HH:mm" : "h:mm AP")
        readonly property string date: Theme.shamsiDate ? Jalali.format(clock.date, true)
                                                        : Qt.formatDateTime(clock.date, "ddd d MMM")
        horizontalAlignment: Text.AlignHCenter
        text: btn.vertical ? Qt.formatDateTime(clock.date, Theme.clock24h ? "HH\nmm" : "hh\nmm")
                           : date + "   " + time
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(13 * Theme.fontScale)
        font.weight: Font.Bold
        color: btn.open ? Theme.accentFg : Theme.ink
    }
}
