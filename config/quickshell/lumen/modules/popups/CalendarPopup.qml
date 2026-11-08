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
        // The new month slides in from the side you're going to.
        monthIn.dir = n;
        monthIn.restart();
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
    // Always six weeks (42 days), so the popup keeps its height from month
    // to month. Days of the months before and after are shown faintly.
    readonly property var cells: {
        const lead = (new Date(viewYear, viewMonth, 1).getDay() - weekStart + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(viewYear, viewMonth, 1 - lead + i);
            out.push({ day: d.getDate(), inMonth: d.getMonth() === viewMonth, y: d.getFullYear(), m: d.getMonth() });
        }
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
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
        Btn { icon: "chevron-right"; variant: "ghost"; onClicked: cal.step(1) }
    }

    GridLayout {
        id: days
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 3
        columnSpacing: 3
        transform: Translate { id: daysShift }

        ParallelAnimation {
            id: monthIn
            property int dir: 1
            NumberAnimation { target: daysShift; property: "x"; from: 18 * monthIn.dir; to: 0; duration: Theme.animNormal; easing.type: Theme.easeOut }
            NumberAnimation { target: days; property: "opacity"; from: 0.2; to: 1; duration: Theme.animNormal; easing.type: Theme.easeOut }
        }

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
                required property var modelData
                readonly property bool isToday: clock.date.getFullYear() === modelData.y
                    && clock.date.getMonth() === modelData.m && clock.date.getDate() === modelData.day

                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.r(8)
                color: isToday ? Theme.accent : "transparent"
                Txt {
                    anchors.centerIn: parent
                    text: day.modelData.day
                    size: 13
                    strong: day.isToday
                    color: day.isToday ? Theme.accentFg : day.modelData.inMonth ? Theme.ink : Theme.muted
                    opacity: day.modelData.inMonth || day.isToday ? 1 : 0.45
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
