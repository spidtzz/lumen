import QtQuick
import QtQuick.Layouts
import qs.services

// Panel-coloured card for bar popups. Clicks inside don't close the popup.
Rectangle {
    id: card

    default property alias content: col.data
    property int padding: 16
    property alias spacing: col.spacing

    implicitHeight: col.implicitHeight + padding * 2
    radius: Theme.radius
    color: Theme.panel
    border.width: 1
    border.color: Theme.line

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    HoverHandler { onHoveredChanged: Panels.popupHovered = hovered }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.padding
        spacing: 14
    }
}
