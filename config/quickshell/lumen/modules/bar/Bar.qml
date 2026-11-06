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

        HoverHandler { onHoveredChanged: Panels.barHovered = hovered }

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
    // A popup window is always drawn above other windows. Clicks elsewhere
    // close it via Panels.click() (reported by the input watcher); there's no
    // pointer grab, so the bar button that opened it can close it again.
    PopupWindow {
        id: popupHost

        readonly property bool mine: Panels.popup !== "" && Panels.popupScreen === bar.screen
        readonly property var content: popupLoader.item

        anchor.window: bar
        anchor.rect: bar.popupRect(implicitWidth, implicitHeight, Panels.popupAnchor)
        implicitWidth: content ? content.implicitWidth : 1
        implicitHeight: content ? content.implicitHeight : 1
        grabFocus: false
        color: "transparent"
        visible: false

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
    // Corner or edge from Settings > Notifications, kept clear of the bar.
    PopupWindow {
        id: notifHost

        readonly property int w: 380
        readonly property var pos: (Theme.conf.notif_position || "top-right").split("-")
        anchor.window: bar
        anchor.rect: {
            const g = Theme.gap, t = Theme.barThickness;
            const sw = bar.screen.width, sh = bar.screen.height, h = implicitHeight;
            // The free area of the screen, in screen coordinates.
            const left = (bar.edge === "left" ? t + 4 : g);
            const right = sw - (bar.edge === "right" ? t + 4 : g);
            const top = (bar.edge === "top" ? t + 4 : g);
            const bottom = sh - (bar.edge === "bottom" ? t + 4 : g);
            const x = pos[1] === "left" ? left : pos[1] === "center" ? (sw - w) / 2 : right - w;
            const y = pos[0] === "bottom" ? bottom - h : top;
            // This bar window's position on the screen.
            const ox = bar.edge === "right" ? sw - t : 0;
            const oy = bar.edge === "bottom" ? sh - t : 0;
            return Qt.rect(x - ox, y - oy, 1, 1);
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
