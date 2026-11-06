import QtQuick
import Quickshell
import qs.services
import qs.components

// One bar per screen, on the edge chosen in Settings (top, bottom, left or
// right), as a floating rounded panel:
//   [launcher] app class ........ [workspaces] ........ [tray] time [QS]
// The workspaces stay centred however wide the sides get. On a vertical bar
// the app name is hidden (there's no room for it).
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property string edge: Theme.barPosition
    readonly property bool vertical: edge === "left" || edge === "right"

    anchors {
        top: bar.edge !== "bottom"
        bottom: bar.edge !== "top"
        left: bar.edge !== "right"
        right: bar.edge !== "left"
    }
    implicitHeight: vertical ? 0 : Theme.barThickness
    implicitWidth: vertical ? Theme.barThickness : 0

    // bspwm padding is managed by shell.qml, so don't reserve space twice.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // An item's rectangle in screen coordinates, for placing popups.
    function anchorOf(item) {
        const p = item.mapToItem(null, 0, 0);
        const ox = edge === "right" ? screen.width - Theme.barThickness : 0;
        const oy = edge === "bottom" ? screen.height - Theme.barThickness : 0;
        return Qt.rect(p.x + ox, p.y + oy, item.width, item.height);
    }

    Rectangle {
        id: body
        anchors.fill: parent
        // Gap on the screen edge and both sides; none toward the windows,
        // because bspwm's window_gap already spaces them.
        anchors.topMargin: bar.edge === "bottom" ? 0 : Theme.gap
        anchors.bottomMargin: bar.edge === "top" ? 0 : Theme.gap
        anchors.leftMargin: bar.edge === "right" ? 0 : Theme.gap
        anchors.rightMargin: bar.edge === "left" ? 0 : Theme.gap

        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.line
        border.width: 1

        WheelHandler {
            onWheel: event => Bspwm.cycleDesktop(event.angleDelta.y < 0)
        }

        // ---- start: launcher + focused app ----
        Grid {
            id: start
            anchors.left: bar.vertical ? undefined : parent.left
            anchors.top: bar.vertical ? parent.top : undefined
            anchors.leftMargin: 5
            anchors.topMargin: 5
            anchors.verticalCenter: bar.vertical ? undefined : parent.verticalCenter
            anchors.horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
            columns: bar.vertical ? 1 : 2
            spacing: 10
            verticalItemAlignment: Grid.AlignVCenter
            horizontalItemAlignment: Grid.AlignHCenter

            LauncherButton {}
            AppLabel {
                visible: !bar.vertical
                // Never run into the centred workspaces.
                maxWidth: Math.max(0, body.width / 2 - center.width / 2 - 26 - 10 - 5 - 16)
            }
        }

        // ---- centre: workspaces ----
        Workspaces {
            id: center
            anchors.centerIn: parent
            screenName: bar.screen ? bar.screen.name : ""
            vertical: bar.vertical
        }

        // ---- end: tray, time, quick settings ----
        Grid {
            id: end
            anchors.right: bar.vertical ? undefined : parent.right
            anchors.bottom: bar.vertical ? parent.bottom : undefined
            anchors.rightMargin: 5
            anchors.bottomMargin: 5
            anchors.verticalCenter: bar.vertical ? undefined : parent.verticalCenter
            anchors.horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
            columns: bar.vertical ? 1 : 3
            spacing: 6
            verticalItemAlignment: Grid.AlignVCenter
            horizontalItemAlignment: Grid.AlignHCenter

            TrayArea { bar: bar; vertical: bar.vertical }
            TimeButton { bar: bar; vertical: bar.vertical }
            QsButton { bar: bar; vertical: bar.vertical }
        }
    }
}
