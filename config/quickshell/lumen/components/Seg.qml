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
    radius: Theme.r(10)
    color: Theme.field
    border.width: 1
    border.color: Theme.line

    readonly property int current: options.findIndex(o => o.value === value)

    // The highlight slides to the chosen option.
    Rectangle {
        visible: seg.current >= 0
        readonly property real cell: (seg.width - 8 - 4 * (seg.options.length - 1)) / Math.max(1, seg.options.length)
        x: 4 + seg.current * (cell + 4)
        y: 4
        width: cell
        height: seg.height - 8
        radius: Theme.r(7)
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeInOut } }
    }

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
                Layout.preferredWidth: 1   // equal widths, matching the highlight
                Layout.fillHeight: true
                radius: Theme.r(7)
                color: !selected && hover.hovered ? Theme.panel : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }

                Txt {
                    anchors.centerIn: parent
                    text: opt.modelData.label
                    size: 13
                    strong: true
                    color: opt.selected ? Theme.accentFg : Theme.ink
                    Behavior on color { ColorAnimation { duration: Theme.animNormal; easing.type: Theme.easeInOut } }
                    wrapMode: Text.NoWrap
                }
                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: if (!opt.selected) seg.picked(opt.modelData.value) }
            }
        }
    }
}
