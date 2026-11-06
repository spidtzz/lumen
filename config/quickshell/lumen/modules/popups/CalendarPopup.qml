import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components
import "../../components/Jalali.js" as Jalali

// Mini calendar with Gregorian and Shamsi views, like the demo's date picker.
PopupCard {
    id: cal

    implicitWidth: 320

    property bool shamsi: Theme.shamsiDate
    property int viewYear: 0
    property int viewMonth: 0   // 1-12

    readonly property var monthsG: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var weekG: ["S", "M", "T", "W", "T", "F", "S"]
    readonly property var weekJ: ["ش", "ی", "د", "س", "چ", "پ", "ج"]   // Saturday first

    SystemClock { id: clock; precision: SystemClock.Hours }

    function today() {
        const d = clock.date;
        return shamsi ? Jalali.fromDate(d) : { y: d.getFullYear(), m: d.getMonth() + 1, d: d.getDate() };
    }
    function goToday() { const t = today(); viewYear = t.y; viewMonth = t.m; }
    function step(n) {
        let m = viewMonth + n, y = viewYear;
        if (m < 1) { m = 12; y--; }
        if (m > 12) { m = 1; y++; }
        viewMonth = m; viewYear = y;
    }
    function digits(v) { return shamsi ? Jalali.faDigits(v) : String(v); }

    onShamsiChanged: goToday()
    Component.onCompleted: goToday()

    // Cells for the visible month: blanks, then 1..length.
    readonly property var cells: {
        if (viewMonth === 0) return [];
        const first = shamsi ? Jalali.toDate(viewYear, viewMonth, 1) : new Date(viewYear, viewMonth - 1, 1);
        const len = shamsi ? Jalali.monthLength(viewYear, viewMonth) : new Date(viewYear, viewMonth, 0).getDate();
        const weekStart = shamsi ? 6 : 0;
        const blanks = (first.getDay() - weekStart + 7) % 7;
        const out = [];
        for (let i = 0; i < blanks; i++) out.push(0);
        for (let d = 1; d <= len; d++) out.push(d);
        return out;
    }

    Seg {
        Layout.fillWidth: true
        options: [{ label: "Gregorian", value: false }, { label: "Shamsi", value: true }]
        value: cal.shamsi
        onPicked: v => cal.shamsi = v
    }

    RowLayout {
        Layout.fillWidth: true
        Btn { icon: "chevron-left"; variant: "ghost"; onClicked: cal.step(-1) }
        Txt {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: (cal.shamsi ? Jalali.MONTHS_FA[cal.viewMonth - 1] : cal.monthsG[cal.viewMonth - 1] || "") + " " + cal.digits(cal.viewYear)
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
        layoutDirection: cal.shamsi ? Qt.RightToLeft : Qt.LeftToRight

        Repeater {
            model: cal.shamsi ? cal.weekJ : cal.weekG
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
                readonly property var t: cal.today()
                readonly property bool isToday: modelData > 0 && t.y === cal.viewYear && t.m === cal.viewMonth && t.d === modelData

                Layout.fillWidth: true
                implicitHeight: 34
                radius: 8
                color: isToday ? Theme.accent : "transparent"
                Txt {
                    anchors.centerIn: parent
                    visible: day.modelData > 0
                    text: cal.digits(day.modelData)
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
            text: cal.shamsi ? Qt.formatDate(clock.date, "d MMMM yyyy") : Jalali.format(clock.date, true)
            muted: true
            size: 12
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
        Btn { text: "Today"; onClicked: cal.goToday() }
    }
}
