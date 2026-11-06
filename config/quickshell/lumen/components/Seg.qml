import QtQuick
import QtQuick.Layouts
import qs.services

// Segmented control: exactly one option active.
// options: [{ label, value }]
Rectangle {
    id: seg

    property var options: []
    property var value
    signal picked(var value)

    implicitWidth: Math.max(220, options.length * 84)
    implicitHeight: 38
    radius: 10
    color: Theme.field
    border.width: 1
    border.color: Theme.line

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Repeater {
            model: seg.options
            delegate: Rectangle {
                id: opt
                required property var modelData
                readonly property bool selected: modelData.value === seg.value

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 7
                color: selected ? Theme.accent : hover.hovered ? Theme.panel : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Txt {
                    anchors.centerIn: parent
                    text: opt.modelData.label
                    size: 13
                    strong: true
                    color: opt.selected ? Theme.accentFg : Theme.ink
                    wrapMode: Text.NoWrap
                }
                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: if (!opt.selected) seg.picked(opt.modelData.value) }
            }
        }
    }
}
