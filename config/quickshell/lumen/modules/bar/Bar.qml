import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

// One bar per screen. It sits on the edge chosen in settings.conf
// (top, bottom, left or right) as a floating rounded panel.
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

        GridLayout {
            anchors.fill: parent
            anchors.margins: 5
            rowSpacing: 6
            columnSpacing: 6
            columns: bar.vertical ? 1 : 4  // four items: one row or one column

            Workspaces {
                screenName: bar.screen ? bar.screen.name : ""
                vertical: bar.vertical
                Layout.alignment: Qt.AlignCenter
            }

            Item {
                Layout.fillWidth: !bar.vertical
                Layout.fillHeight: bar.vertical
            }

            Clock {
                vertical: bar.vertical
                Layout.alignment: Qt.AlignCenter
            }

            Avatar {
                size: 26
                Layout.alignment: Qt.AlignCenter
            }
        }
    }
}
