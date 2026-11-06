import QtQuick
import Quickshell
import qs.services
import qs.components
import qs.modules.popups

// One bar per screen, on the edge chosen in Settings (top, bottom, left or
// right), as a floating rounded panel:
//   [launcher] app class ........ [workspaces] ........ [tray] [EN] time [QS]
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

    // An item's rectangle in this window's coordinates, for placing popups.
    function anchorOf(item) {
        const p = item.mapToItem(null, 0, 0);
        return Qt.rect(p.x, p.y, item.width, item.height);
    }

    // Where a w×h popup goes: next to the button that opened it (or the end of
    // the bar), on the window side, inside the screen.
    function popupRect(w, h, anchor) {
        const g = Theme.gap;
        const has = anchor && anchor.width > 0;
        if (!vertical) {
            const x = has ? anchor.x + anchor.width / 2 - w / 2 : width - w - g;
            return Qt.rect(Math.max(g, Math.min(x, width - w - g)), edge === "top" ? height + 4 : -h - 4, 1, 1);
        }
        const y = has ? anchor.y : g;
        return Qt.rect(edge === "left" ? width + 4 : -w - 4, Math.max(g, Math.min(y, height - h - g)), 1, 1);
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
            columns: bar.vertical ? 1 : 4
            spacing: 6
            verticalItemAlignment: Grid.AlignVCenter
            horizontalItemAlignment: Grid.AlignHCenter

            TrayArea { bar: bar; vertical: bar.vertical }
            KeyboardButton { bar: bar; vertical: bar.vertical }
            TimeButton { bar: bar; vertical: bar.vertical }
            QsButton { bar: bar; vertical: bar.vertical }
        }
    }

    // ---- popups: calendar, quick settings, tray, menus ----
    // A popup window is always drawn above other windows, and grabFocus closes
    // it when you click anywhere else.
    PopupWindow {
        id: popupHost

        readonly property bool mine: Panels.popup !== "" && Panels.popupScreen === bar.screen
        readonly property var content: popupLoader.item

        anchor.window: bar
        anchor.rect: bar.popupRect(implicitWidth, implicitHeight, Panels.popupAnchor)
        implicitWidth: content ? content.implicitWidth : 1
        implicitHeight: content ? content.implicitHeight : 1
        grabFocus: true
        color: "transparent"
        visible: false

        // Set imperatively: a click outside sets visible = false by itself.
        function sync() {
            const show = mine && content !== null;
            if (visible !== show) visible = show;
        }
        onMineChanged: sync()
        onContentChanged: sync()
        onVisibleChanged: if (!visible && mine) Panels.closePopup()

        Loader {
            id: popupLoader
            active: popupHost.mine
            width: item ? item.implicitWidth : 0
            height: item ? item.implicitHeight : 0
            source: {
                switch (Panels.popup) {
                case "calendar": return "../popups/CalendarPopup.qml";
                case "qs": return "../popups/QuickSettings.qml";
                case "tray": return "../popups/TrayPopup.qml";
                case "traymenu": return "../popups/TrayMenu.qml";
                case "keyboard": return "../popups/KeyboardMenu.qml";
                default: return "";
                }
            }
        }
    }

    // ---- notification popups (on the focused screen) ----
    PopupWindow {
        id: notifHost

        readonly property int w: 380
        anchor.window: bar
        anchor.rect: {
            const g = Theme.gap;
            if (bar.edge === "top") return Qt.rect(bar.width - w - g, bar.height + 4, 1, 1);
            if (bar.edge === "bottom") return Qt.rect(bar.width - w - g, -implicitHeight - 4, 1, 1);
            if (bar.edge === "left") return Qt.rect(bar.screen.width - w - g, g, 1, 1);
            return Qt.rect(-w - 4, g, 1, 1);
        }
        implicitWidth: w
        implicitHeight: Math.max(1, notifStack.implicitHeight)
        color: "transparent"
        visible: Notifs.popups.length > 0 && bar.screen === Panels.focusedScreen() && Panels.popup !== "qs"

        Column {
            id: notifStack
            width: notifHost.w
            spacing: 8
            Repeater {
                model: Notifs.popups
                delegate: NotificationCard {
                    id: card
                    required property var modelData
                    width: notifHost.w
                    notification: modelData
                    popup: true
                    onDismissed: modelData.dismiss()
                    Timer {
                        running: !card.critical && !card.hovered
                        interval: card.n && card.n.expireTimeout > 0 ? card.n.expireTimeout : 5000
                        onTriggered: Notifs.dismissPopup(card.modelData)
                    }
                }
            }
        }
    }
}
