import QtQuick
import QtQuick.Layouts
import qs.services

// The demo's card: panel colour, 1px line border, 14px corners.
Rectangle {
    id: card

    property string title
    property string description
    property bool highlight: false
    default property alias content: col.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 32
    radius: Theme.radius
    color: Theme.panel
    border.width: highlight ? 2 : 1
    border.color: highlight ? Theme.accent : Theme.line

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 10

        ColumnLayout {
            visible: card.title !== "" || card.description !== ""
            spacing: 2
            Layout.fillWidth: true
            Txt { text: card.title; size: 16; strong: true; visible: text !== ""; Layout.fillWidth: true }
            Txt { text: card.description; size: 13; muted: true; visible: text !== ""; Layout.fillWidth: true }
        }
    }
}
