import QtQuick
import QtQuick.Layouts
import qs.services

// Quick Settings toggle tile: icon, label and a short status line.
Rectangle {
    id: tile

    property string icon
    property string label
    property string status
    property bool active: false
    signal clicked()
    signal rightClicked()

    Layout.fillWidth: true
    implicitHeight: 56
    radius: 12
    color: active ? Theme.accent : hover.hovered ? Qt.lighter(Theme.field, Theme.dark ? 1.25 : 0.97) : Theme.field
    border.width: 1
    border.color: active ? Theme.accent : Theme.line
    opacity: enabled ? 1 : 0.5
    scale: tap.pressed ? 0.98 : 1
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: 80 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 12

        Icon { name: tile.icon; size: 19; color: tile.active ? Theme.accentFg : Theme.ink }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt {
                Layout.fillWidth: true
                text: tile.label
                size: 13
                strong: true
                color: tile.active ? Theme.accentFg : Theme.ink
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
            Txt {
                Layout.fillWidth: true
                visible: tile.status !== ""
                text: tile.status
                size: 11
                color: tile.active ? Theme.accentFg : Theme.muted
                opacity: tile.active ? 0.85 : 1
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: tile.clicked() }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: tile.rightClicked() }
}
