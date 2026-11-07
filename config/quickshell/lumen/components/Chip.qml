import QtQuick
import QtQuick.Layouts
import qs.services

// Pill-shaped toggle chip. With `removable`, shows a × that emits removed().
Rectangle {
    id: chip

    property string text
    property bool checked: false
    property bool removable: false
    signal clicked()
    signal removed()

    implicitWidth: row.implicitWidth + (removable ? 16 : 26)
    implicitHeight: 32
    radius: Theme.r(height / 2)
    color: checked ? Theme.accent : Theme.field
    border.width: 1
    border.color: checked || hover.hovered ? Theme.accent : Theme.line
    scale: tap.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: chip.removable ? 3 : 0
        spacing: 4
        Txt {
            text: chip.text
            size: 13
            strong: true
            color: chip.checked ? Theme.accentFg : Theme.ink
            wrapMode: Text.NoWrap
        }
        Rectangle {
            visible: chip.removable
            width: 22; height: 22; radius: Theme.r(11)
            color: xHover.hovered ? Theme.panel : "transparent"
            Icon {
                anchors.centerIn: parent
                name: "x"
                size: 13
                color: chip.checked ? Theme.accentFg : Theme.muted
            }
            HoverHandler { id: xHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: chip.removed() }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: chip.clicked() }
}
