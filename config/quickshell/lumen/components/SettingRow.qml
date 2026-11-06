import QtQuick
import QtQuick.Layouts

// A label (and optional description) on the left, controls on the right.
RowLayout {
    id: row

    property string label
    property string description
    default property alias controls: slot.data

    Layout.fillWidth: true
    spacing: 16

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
