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

    // Room for the widest possible time, so the bar never shifts.
    TextMetrics {
        id: widest
        font: timeText.font
        text: Theme.clock24h ? "88:88"
            : "88:88 " + (Qt.locale().amText.length > Qt.locale().pmText.length ? Qt.locale().amText : Qt.locale().pmText)
    }
    contentWidth: widest.advanceWidth + 2

    Text {
        id: timeText
        width: btn.vertical ? implicitWidth : btn.contentWidth
        horizontalAlignment: Text.AlignHCenter
        text: btn.vertical ? Qt.formatDateTime(clock.date, Theme.clock24h ? "HH\nmm" : "hh\nmm")
                           : Qt.formatDateTime(clock.date, Theme.clock24h ? "HH:mm" : "h:mm AP")
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(15 * Theme.fontScale)
        font.weight: Font.Bold
        font.features: ({ "tnum": 1 })   // digits of equal width
        color: btn.open ? Theme.barAccentFg : Theme.barInk
    }
}
