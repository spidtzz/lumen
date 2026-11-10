import QtQuick
import QtQuick.Layouts
import qs.services

// A label (and optional description) on the left, controls on the right.
// With `icon`, a small icon tile leads the row. Rows that follow another row
// in the same card get a thin line between them.
Item {
    id: row

    property string label
    property string description
    property string icon: ""
    readonly property bool isSettingRow: true
    default property alias controls: slot.data

    // The visible item before this one (skipping hidden ones) is a row too?
    readonly property bool afterRow: {
        if (!parent) return false;
        const kids = parent.children;
        let prev = null;
        for (let i = 0; i < kids.length; i++) {
            if (kids[i] === row) break;
            if (kids[i].visible) prev = kids[i];
        }
        return prev !== null && prev.isSettingRow === true;
    }

    Layout.fillWidth: true
    implicitWidth: layout.implicitWidth
    // a little air above and below, so rows separated by a line breathe
    implicitHeight: layout.implicitHeight + (afterRow ? 4 : 0)

    Rectangle {   // divider, halfway into the space above
        visible: row.afterRow
        x: 0
        y: -3
        width: row.width
        height: 1
        color: Theme.line
        opacity: 0.6
    }

    RowLayout {
    id: layout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    spacing: 14

    Rectangle {
        visible: row.icon !== ""
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 34
        implicitHeight: 34
        radius: Theme.r(9)
        color: Theme.field
        Icon { anchors.centerIn: parent; name: row.icon; size: 17; color: Theme.accent }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Txt { text: row.label; strong: true; Layout.fillWidth: true }
        Txt { text: row.description; muted: true; size: 12; visible: text !== ""; Layout.fillWidth: true }
    }

    RowLayout {
        id: slot
        spacing: 8
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }
}
}
