import QtQuick
import Quickshell
import qs.services

// The time. Click for the calendar.
BarButton {
    id: btn

    property var bar

    open: Panels.popup === "calendar" && Panels.popupScreen === bar.screen
    onClicked: Panels.togglePopup("calendar", bar.screen, bar.anchorOf(btn))

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Text {
        horizontalAlignment: Text.AlignHCenter
        text: btn.vertical ? Qt.formatDateTime(clock.date, Theme.clock24h ? "HH\nmm" : "hh\nmm")
                           : Qt.formatDateTime(clock.date, Theme.clock24h ? "HH:mm" : "h:mm AP")
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(15 * Theme.fontScale)
        font.weight: Font.Bold
        color: btn.open ? Theme.accentFg : Theme.ink
    }
}
