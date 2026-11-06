import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// Mini calendar. Month and day names, and the first day of the week, follow
// the system's regional format.
PopupCard {
    id: cal

    implicitWidth: 320

    readonly property var loc: Qt.locale()
    property int viewYear: 0
    property int viewMonth: 0   // 0-11

    SystemClock { id: clock; precision: SystemClock.Hours }

    function goToday() { viewYear = clock.date.getFullYear(); viewMonth = clock.date.getMonth(); }
    function step(n) {
        let m = viewMonth + n, y = viewYear;
        if (m < 0) { m = 11; y--; }
        if (m > 11) { m = 0; y++; }
        viewMonth = m; viewYear = y;
    }
    Component.onCompleted: goToday()

    // Qt: firstDayOfWeek is 1 (Monday) to 7 (Sunday); JS getDay() is 0 (Sunday) to 6.
    readonly property int weekStart: loc.firstDayOfWeek % 7
    readonly property var weekdays: {
        const out = [];
        for (let i = 0; i < 7; i++)
            out.push(loc.dayName((weekStart + i) % 7, Locale.NarrowFormat));
        return out;
    }
    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1);
        const len = new Date(viewYear, viewMonth + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < (first.getDay() - weekStart + 7) % 7; i++) out.push(0);
        for (let d = 1; d <= len; d++) out.push(d);
        return out;
    }

    RowLayout {
        Layout.fillWidth: true
        Btn { icon: "chevron-left"; variant: "ghost"; onClicked: cal.step(-1) }
        Txt {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: cal.loc.standaloneMonthName(cal.viewMonth, Locale.LongFormat) + " " + cal.viewYear
            strong: true
            size: 15
        }
        Btn { icon: "chevron-right"; variant: "ghost"; onClicked: cal.step(1) }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 3
        columnSpacing: 3

        Repeater {
            model: cal.weekdays
            delegate: Txt {
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                size: 12
                muted: true
                strong: true
            }
        }

        Repeater {
            model: cal.cells
            delegate: Rectangle {
                id: day
                required property int modelData
                readonly property bool isToday: modelData > 0 && clock.date.getFullYear() === cal.viewYear
                    && clock.date.getMonth() === cal.viewMonth && clock.date.getDate() === modelData

                Layout.fillWidth: true
                implicitHeight: 34
                radius: 8
                color: isToday ? Theme.accent : "transparent"
                Txt {
                    anchors.centerIn: parent
                    visible: day.modelData > 0
                    text: day.modelData
                    size: 13
                    strong: day.isToday
                    color: day.isToday ? Theme.accentFg : Theme.ink
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Txt {
            Layout.fillWidth: true
            text: clock.date.toLocaleDateString(cal.loc, Locale.LongFormat)
            muted: true
            size: 12
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
        Btn { text: "Today"; onClicked: cal.goToday() }
    }
}
