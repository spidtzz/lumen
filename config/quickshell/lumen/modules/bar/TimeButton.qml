import QtQuick
import Quickshell
import qs.services

// The time. Click for the calendar. Seconds (Settings > Bar): shown, or the
// colon flashing once a second.
BarButton {
    id: btn

    property var bar

    open: Panels.popup === "calendar" && Panels.popupScreen === bar.screen
    onClicked: Panels.togglePopup("calendar", bar.screen, bar.anchorOf(btn))

    readonly property string seconds: Theme.clockSeconds
    SystemClock { id: clock; precision: btn.seconds === "off" ? SystemClock.Minutes : SystemClock.Seconds }

    readonly property string ampm: Theme.clock24h ? "" : " " + Qt.formatDateTime(clock.date, "AP")
    readonly property bool blinkOn: clock.date.getSeconds() % 2 === 0

    // Room for the widest possible time, so the bar never shifts.
    TextMetrics {
        id: widest
        font: probe.font
        text: (btn.seconds === "show" ? "88:88:88" : "88:88")
            + (Theme.clock24h ? "" : " " + (Qt.locale().amText.length > Qt.locale().pmText.length ? Qt.locale().amText : Qt.locale().pmText))
    }
    contentWidth: widest.advanceWidth + 2

    component Part: Text {
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(15 * Theme.fontScale)
        font.weight: Font.Bold
        font.features: ({ "tnum": 1 })   // digits of equal width
        color: btn.open ? Theme.barAccentFg : Theme.barInk
    }
    // (Hidden parts take no room: the button is sized from what's inside.)
    Part { id: probe; visible: false; width: 0; height: 0; text: "8" }

    // Side bars: hours over minutes (over seconds).
    Part {
        visible: btn.vertical
        width: visible ? implicitWidth : 0
        height: visible ? implicitHeight : 0
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(clock.date, (Theme.clock24h ? "HH\nmm" : "hh\nmm") + (btn.seconds === "show" ? "\nss" : ""))
    }

    // Top and bottom bars: hours, the colon, the rest.
    Item {
        visible: !btn.vertical
        width: visible ? btn.contentWidth : 0
        height: visible ? row.implicitHeight : 0
        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            Part { text: Qt.formatDateTime(clock.date, Theme.clock24h ? "HH" : "h") }
            Part {
                text: ":"
                opacity: btn.seconds !== "blink" || btn.blinkOn ? 1 : 0.15
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
            Part {
                text: Qt.formatDateTime(clock.date, btn.seconds === "show" ? "mm:ss" : "mm") + btn.ampm
            }
        }
    }
}
