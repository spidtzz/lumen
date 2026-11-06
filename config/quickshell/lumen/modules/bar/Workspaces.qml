import QtQuick
import qs.services

// Desktop chips, styled like the demo's toggle chips: the focused desktop is
// an accent pill, occupied ones show a dot, free ones are dimmed.
Grid {
    id: root

    property string screenName: ""
    property bool vertical: false

    columns: vertical ? 1 : 99  // one row, or one column
    spacing: 4

    Repeater {
        model: Bspwm.desktopsFor(root.screenName)

        delegate: Rectangle {
            id: chip
            required property var modelData

            readonly property bool active: modelData.focused
            readonly property int along: active ? 44 : 26  // length along the bar

            width: root.vertical ? 26 : along
            height: root.vertical ? along : 26
            radius: 999
            color: active ? Theme.accent : (hover.hovered ? Theme.field : "transparent")
            border.width: modelData.urgent && !active ? 1 : 0
            border.color: Theme.danger

            Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: chip.modelData.name
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: chip.active ? Theme.accentFg
                     : chip.modelData.occupied ? Theme.ink : Theme.muted
                opacity: chip.active || chip.modelData.occupied ? 1 : 0.6
            }

            // occupied dot under the number
            Rectangle {
                visible: chip.modelData.occupied && !chip.active
                width: 4; height: 4; radius: 2
                color: Theme.accent
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Bspwm.focusDesktop(chip.modelData.name) }
        }
    }
}
