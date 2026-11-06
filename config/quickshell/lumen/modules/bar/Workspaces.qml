import QtQuick
import qs.services
import qs.components

// Desktop chips, a page at a time: with 5 per page, desktops 1-5 show until
// you go to 6, then 6-10. Arrows appear when other pages have windows.
// The page size is in Settings > Bar.
Grid {
    id: root

    property string screenName: ""
    property bool vertical: false

    readonly property var all: Bspwm.desktopsFor(screenName)
    readonly property int per: Math.max(3, +(Theme.conf.bar_workspaces || 5))
    readonly property int focusedIndex: Math.max(0, all.findIndex(d => d.focused))
    readonly property int page: Math.floor(focusedIndex / per)
    readonly property int pages: Math.ceil(all.length / per)
    readonly property var shown: all.slice(page * per, page * per + per)
    readonly property bool moreBefore: all.slice(0, page * per).some(d => d.occupied || d.urgent)
    readonly property bool moreAfter: all.slice((page + 1) * per).some(d => d.occupied || d.urgent)

    columns: vertical ? 1 : 99
    spacing: 4

    // Scroll over the workspaces to switch desktops.
    WheelHandler {
        onWheel: event => Bspwm.cycleDesktop(event.angleDelta.y < 0)
    }

    component PageArrow: Rectangle {
        id: arrow
        property bool forward: true
        width: root.vertical ? 26 : 16
        height: root.vertical ? 16 : 26
        radius: 8
        color: arrowHover.hovered ? Theme.field : "transparent"
        Icon {
            anchors.centerIn: parent
            name: root.vertical ? (arrow.forward ? "chevron-down" : "chevron-up")
                                : (arrow.forward ? "chevron-right" : "chevron-left")
            size: 13
            color: Theme.muted
        }
        HoverHandler { id: arrowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            onTapped: {
                const target = root.all[(root.page + (arrow.forward ? 1 : -1)) * root.per];
                if (target) Bspwm.focusDesktop(target.name);
            }
        }
    }

    PageArrow { forward: false; visible: root.moreBefore }

    Repeater {
        model: root.shown

        delegate: Rectangle {
            id: chip
            required property var modelData

            readonly property bool active: modelData.focused
            readonly property int along: active ? 40 : 26

            width: root.vertical ? 26 : along
            height: root.vertical ? along : 26
            radius: 13
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
                font.pixelSize: Math.round(13 * Theme.fontScale)
                font.weight: Font.Bold
                color: chip.active ? Theme.accentFg
                     : chip.modelData.occupied ? Theme.ink : Theme.muted
                opacity: chip.active || chip.modelData.occupied ? 1 : 0.6
            }

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

    PageArrow { forward: true; visible: root.moreAfter }
}
