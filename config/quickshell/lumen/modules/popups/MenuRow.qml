import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// A row in a popup menu, styled like the demo's dropdown list.
Rectangle {
    id: row

    property string text
    property string icon
    property bool checked: false
    property bool submenu: false
    property bool danger: false
    signal clicked()

    Layout.fillWidth: true
    implicitWidth: rowLayout.implicitWidth + 22
    implicitHeight: 36
    radius: 8
    opacity: enabled ? 1 : 0.45
    color: hover.hovered && enabled ? Theme.field : "transparent"

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        spacing: 10
        Icon {
            visible: row.icon !== ""
            name: row.icon
            size: 16
            color: row.danger ? Theme.danger : Theme.ink
        }
        Txt {
            Layout.fillWidth: true
            text: row.text
            strong: row.checked
            color: row.danger ? Theme.danger : Theme.ink
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
        Icon { visible: row.checked; name: "check"; size: 15; color: Theme.accent }
        Icon { visible: row.submenu; name: "chevron-right"; size: 15; color: Theme.muted }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: row.enabled; onTapped: row.clicked() }
}
