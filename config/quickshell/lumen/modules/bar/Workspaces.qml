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
    spacing: style === "dots" ? 0 : 2

    // Scroll over the workspaces to switch desktops.
    WheelHandler {
        onWheel: event => Bspwm.cycleDesktop(event.angleDelta.y < 0)
    }

    // Arrows keep their space (when there's more than one page), and a short
    // last page is padded, so the workspaces always take the same room.
    component PageArrow: Rectangle {
        id: arrow
        property bool forward: true
        property bool shown: false
        property Item ws: null   // the Workspaces grid (passed in: inline components don't see its id)
        visible: arrow.ws.pages > 1
        opacity: shown ? 1 : 0
        enabled: shown
        width: arrow.ws.vertical ? 26 : 16
        height: arrow.ws.vertical ? 16 : 26
        radius: Theme.r(8)
        color: arrowHover.hovered ? Theme.barField : "transparent"
        Icon {
            anchors.centerIn: parent
            name: arrow.ws.vertical ? (arrow.forward ? "chevron-down" : "chevron-up")
                                : (arrow.forward ? "chevron-right" : "chevron-left")
            size: 13
            color: Theme.barMuted
        }
        HoverHandler { id: arrowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            onTapped: {
                const target = arrow.ws.all[(arrow.ws.page + (arrow.forward ? 1 : -1)) * arrow.ws.per];
                if (target) Bspwm.focusDesktop(target.name);
            }
        }
    }

    PageArrow { ws: root; forward: false; shown: root.moreBefore }

    // Style (Settings > Bar > Workspaces):
    //   pills    numbers; the current one is a wider accent pill (default)
    //   boxes    every desktop the same size; the current one filled
    //   dots     no numbers: dots, the current one a short bar
    //   numbers  numbers only; the current one in the accent with a line under it
    readonly property string style: ["pills", "boxes", "dots", "numbers"].includes(Theme.conf.ws_style)
        ? Theme.conf.ws_style : "pills"
    // Size of one desktop along the bar, and across it.
    readonly property int across: 26
    function along(active) {
        switch (style) {
        case "dots": return active ? 30 : 18;
        case "boxes": return 26;
        case "numbers": return 22;
        default: return active ? 42 : 28;
        }
    }

    Repeater {
        model: root.shown

        delegate: Item {
            id: chip
            required property var modelData

            readonly property bool active: modelData.focused
            readonly property bool occupied: modelData.occupied
            readonly property color fg: active ? (root.style === "numbers" ? Theme.barAccent : Theme.barAccentFg)
                : occupied ? Theme.barInk : Theme.barMuted

            width: root.vertical ? root.across : root.along(active)
            height: root.vertical ? root.along(active) : root.across
            Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

            // Background: pill or box (not for dots and numbers).
            Rectangle {
                anchors.fill: parent
                visible: root.style === "pills" || root.style === "boxes"
                radius: root.style === "boxes" ? Math.max(0, Theme.radiusSmall - 2) : Theme.r(13)
                color: chip.active ? Theme.barAccent
                     : hover.hovered ? Theme.barField
                     : root.style === "boxes" && chip.occupied ? Theme.barField : "transparent"
                border.width: chip.modelData.urgent && !chip.active ? 1 : 0
                border.color: Theme.danger
                Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
            }

            // Number (not for dots).
            Text {
                anchors.centerIn: parent
                visible: root.style !== "dots"
                text: chip.modelData.name
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(13 * Theme.fontScale)
                font.weight: chip.active || chip.occupied ? Font.Bold : Font.Medium
                font.features: ({ "tnum": 1 })
                color: chip.modelData.urgent && !chip.active ? Theme.danger : chip.fg
                opacity: chip.active || chip.occupied ? 1 : 0.65
            }

            // Occupied marker (pills: a dot under the number; numbers: the
            // current one gets a line).
            Rectangle {
                visible: (root.style === "pills" && chip.occupied && !chip.active)
                      || (root.style === "numbers" && chip.active)
                width: root.style === "numbers" ? (root.vertical ? 2 : 12) : 4
                height: root.style === "numbers" ? (root.vertical ? 12 : 2) : 4
                radius: Theme.r(2)
                color: Theme.barAccent
                x: root.vertical && root.style === "numbers" ? 1 : (parent.width - width) / 2
                y: root.vertical && root.style === "numbers" ? (parent.height - height) / 2 : parent.height - height - 2
            }

            // Dots style.
            Rectangle {
                visible: root.style === "dots"
                anchors.centerIn: parent
                width: root.vertical ? 8 : (chip.active ? 22 : 8)
                height: root.vertical ? (chip.active ? 22 : 8) : 8
                radius: Theme.r(4)
                color: chip.modelData.urgent && !chip.active ? Theme.danger
                     : chip.active ? Theme.barAccent : chip.occupied ? Theme.barInk : Theme.barMuted
                opacity: chip.active || chip.occupied ? 1 : 0.45
                scale: hover.hovered && !chip.active ? 1.25 : 1
                Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Bspwm.focusDesktop(chip.modelData.name) }
        }
    }

    Repeater {
        model: root.pages > 1 ? Math.max(0, root.per - root.shown.length) : 0
        delegate: Item {
            width: root.vertical ? root.across : root.along(false)
            height: root.vertical ? root.along(false) : root.across
        }
    }

    PageArrow { ws: root; forward: true; shown: root.moreAfter }
}
