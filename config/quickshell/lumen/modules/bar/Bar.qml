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
    // Not "bar": the buttons have a "bar" property, and inside a Component
    // their own (empty) property would hide an id of the same name.
    id: win

    required property var modelData
    screen: modelData

    readonly property string edge: Theme.barPosition
    readonly property bool vertical: edge === "left" || edge === "right"

    anchors {
        top: win.edge !== "bottom"
        bottom: win.edge !== "top"
        left: win.edge !== "right"
        right: win.edge !== "left"
    }
    implicitHeight: vertical ? 0 : Theme.barDepth
    implicitWidth: vertical ? Theme.barDepth : 0

    // A fullscreen app on this monitor: the bar steps aside (lumen-stack also
    // moves the bar's window below it, so clicks reach the app).
    readonly property bool fullscreenApp: {
        const m = Bspwm.monitorFor(screen ? screen.name : "");
        return m ? m.fullscreen : false;
    }
    onFullscreenAppChanged: if (fullscreenApp && Panels.popupScreen === screen) Panels.closePopup()

    // This window's position on the screen, for placing popups in screen terms.
    readonly property int screenX: edge === "right" && screen ? screen.width - Theme.barDepth : 0
    readonly property int screenY: edge === "bottom" && screen ? screen.height - Theme.barDepth : 0

    // bspwm padding is managed by shell.qml, so don't reserve space twice.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    Component.onCompleted: Panels.bars = Panels.bars.concat([win])
    Component.onDestruction: Panels.bars = Panels.bars.filter(b => b !== win)

    // Sizes of the bar's parts, for `lumen debug` when something looks wrong.
    function debugInfo() {
        const r = it => `${String(it).split("(")[0]} x=${Math.round(it.x)} y=${Math.round(it.y)} w=${Math.round(it.width)} h=${Math.round(it.height)} visible=${it.visible}`;
        const out = [`bar on ${win.screen ? win.screen.name : "?"} ${win.screen ? win.screen.width + "x" + win.screen.height : ""} edge=${win.edge} window=${win.width}x${win.height}`,
                     "  body " + r(body), "  end " + r(end)];
        if (end.item)
            for (const c of end.item.children) out.push("    " + r(c));
        return out.join("\n");
    }

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
        // The bar's inner edge, in this window's coordinates.
        const inner = edge === "top" || edge === "left" ? Theme.barOuter : Theme.barDepth - Theme.barOuter;
        if (!vertical) {
            const x = has ? anchor.x + anchor.width / 2 - w / 2 : width - w - g;
            return Qt.rect(Math.max(g, Math.min(x, width - w - g)), edge === "top" ? inner + 4 : inner - h - 4, 1, 1);
        }
        const y = has ? anchor.y : g;
        return Qt.rect(edge === "left" ? inner + 4 : inner - w - 4, Math.max(g, Math.min(y, height - h - g)), 1, 1);
    }

    // Edge to edge: the curved ends that lead into rounded screen corners.
    Repeater {
        model: Theme.barFillets ? (win.edge === "top" ? ["top-left", "top-right"]
            : win.edge === "bottom" ? ["bottom-left", "bottom-right"]
            : win.edge === "left" ? ["top-left", "bottom-left"] : ["top-right", "bottom-right"]) : []
        delegate: Fillet {
            required property string modelData
            visible: !win.fullscreenApp
            corner: modelData
            r: Theme.screenRadius
            fill: Theme.barBg
            x: win.edge === "left" ? Theme.barSize
             : win.edge === "right" ? win.width - Theme.barSize - r
             : modelData.endsWith("left") ? 0 : win.width - r
            y: win.edge === "top" ? Theme.barSize
             : win.edge === "bottom" ? win.height - Theme.barSize - r
             : modelData.startsWith("top") ? 0 : win.height - r
        }
    }

    Rectangle {
        id: body
        visible: !win.fullscreenApp
        anchors.fill: parent
        // Floating: a gap on the screen edge and both sides; none toward the
        // windows, because bspwm's window_gap already spaces them.
        // Edge to edge: no gaps, and room for the curved ends.
        readonly property int g: Theme.barAttached ? 0 : Theme.gap
        readonly property int extra: Theme.barDepth - Theme.barOuter   // room for the curved ends
        anchors.topMargin: win.edge === "bottom" ? (Theme.barAttached ? extra : 0) : g
        anchors.bottomMargin: win.edge === "top" ? (Theme.barAttached ? extra : 0) : g
        anchors.leftMargin: win.edge === "right" ? (Theme.barAttached ? extra : 0) : g
        anchors.rightMargin: win.edge === "left" ? (Theme.barAttached ? extra : 0) : g

        radius: Theme.barAttached ? 0 : Theme.radius
        color: Theme.barBg
        border.color: Theme.barLine
        border.width: Theme.barAttached ? 0 : 1

        HoverHandler { onHoveredChanged: Panels.barHovered = hovered }

        // ---- start: launcher + focused app ----
        Grid {
            id: start
            anchors.left: win.vertical ? undefined : parent.left
            anchors.top: win.vertical ? parent.top : undefined
            anchors.leftMargin: 5
            anchors.topMargin: 5
            anchors.verticalCenter: win.vertical ? undefined : parent.verticalCenter
            anchors.horizontalCenter: win.vertical ? parent.horizontalCenter : undefined
            columns: win.vertical ? 1 : 2
            spacing: 10
            verticalItemAlignment: Grid.AlignVCenter
            horizontalItemAlignment: Grid.AlignHCenter

            LauncherButton {}
            AppLabel {
                visible: !win.vertical
                // Never run into the centred workspaces.
                maxWidth: Math.max(0, body.width / 2 - center.width / 2 - 26 - 10 - 5 - 16)
            }
        }

        // ---- centre: workspaces ----
        Workspaces {
            id: center
            anchors.centerIn: parent
            screenName: win.screen ? win.screen.name : ""
            vertical: win.vertical
        }

        // ---- end: tray, time, quick settings ----
        // A Row on a horizontal bar and a Column on a vertical one (simpler and
        // more predictable than one Grid that changes its column count).
        Loader {
            id: end
            anchors.right: win.vertical ? undefined : parent.right
            anchors.bottom: win.vertical ? parent.bottom : undefined
            anchors.rightMargin: 5
            anchors.bottomMargin: 5
            anchors.verticalCenter: win.vertical ? undefined : parent.verticalCenter
            anchors.horizontalCenter: win.vertical ? parent.horizontalCenter : undefined
            sourceComponent: win.vertical ? endColumn : endRow
        }

        Component {
            id: endRow
            Row {
                spacing: 6
                RecordingButton { anchors.verticalCenter: parent.verticalCenter }
                TrayArea { bar: win; anchors.verticalCenter: parent.verticalCenter }
                KeyboardButton { bar: win; anchors.verticalCenter: parent.verticalCenter }
                TimeButton { bar: win; anchors.verticalCenter: parent.verticalCenter }
                QsButton { bar: win; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Component {
            id: endColumn
            Column {
                spacing: 6
                RecordingButton { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
                TrayArea { bar: win; vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
                KeyboardButton { bar: win; vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
                TimeButton { bar: win; vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
                QsButton { bar: win; vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }

    // ---- popups: calendar, quick settings, tray, menus ----
    // A popup window is always drawn above other windows. Clicks elsewhere
    // close it via Panels.click() (reported by the input watcher); there's no
    // pointer grab, so the bar button that opened it can close it again.
    PopupWindow {
        id: popupHost

        readonly property bool mine: Panels.popup !== "" && Panels.popupScreen === win.screen
        readonly property var content: popupLoader.item

        anchor.window: win
        anchor.rect: win.popupRect(implicitWidth, implicitHeight, Panels.popupAnchor)
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

    // ---- rounded screen corners (Settings > Appearance) ----
    // Small black corner pieces above everything, one per screen corner.
    Variants {
        model: Theme.screenCorners ? ["top-left", "top-right", "bottom-left", "bottom-right"] : []
        PopupWindow {
            id: cornerWin
            required property string modelData
            anchor.window: win
            anchor.rect: Qt.rect((modelData.endsWith("left") ? 0 : win.screen.width - Theme.screenRadius) - win.screenX,
                                 (modelData.startsWith("top") ? 0 : win.screen.height - Theme.screenRadius) - win.screenY, 1, 1)
            implicitWidth: Theme.screenRadius
            implicitHeight: Theme.screenRadius
            color: "transparent"
            visible: true
            Fillet { corner: cornerWin.modelData; r: Theme.screenRadius; fill: "black" }
        }
    }

    // ---- volume / brightness level (media keys), on the focused screen ----
    // Bottom centre, kept clear of the bar.
    PopupWindow {
        id: osdHost

        readonly property int w: 280
        anchor.window: win
        anchor.rect: {
            const sw = win.screen.width, sh = win.screen.height;
            const x = (sw - w) / 2;
            const y = sh - implicitHeight - (win.edge === "bottom" ? Theme.barReserve + 24 : 48);
            return Qt.rect(x - win.screenX, y - win.screenY, 1, 1);
        }
        implicitWidth: w
        implicitHeight: 56
        color: "transparent"
        visible: Osd.shown && win.screen === Panels.focusedScreen()

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.panel
            border.width: 1
            border.color: Theme.line

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 18
                spacing: 14
                Icon { anchors.verticalCenter: parent.verticalCenter; name: Osd.icon; size: 20 }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: osdHost.w - 18 - 20 - 14 - 14 - 52 - 18
                    height: 8
                    radius: Theme.r(4)
                    color: Theme.field
                    border.width: 1
                    border.color: Theme.line
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Osd.level))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                        Behavior on width { NumberAnimation { duration: Theme.animFast } }
                    }
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 52
                    text: Osd.label
                    size: 12
                    strong: true
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
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
        anchor.window: win
        anchor.rect: {
            const g = Theme.gap, t = Theme.barReserve;
            const sw = win.screen.width, sh = win.screen.height, h = implicitHeight;
            // The free area of the screen, in screen coordinates.
            const left = (win.edge === "left" ? t + 4 : g);
            const right = sw - (win.edge === "right" ? t + 4 : g);
            const top = (win.edge === "top" ? t + 4 : g);
            const bottom = sh - (win.edge === "bottom" ? t + 4 : g);
            const x = pos[1] === "left" ? left : pos[1] === "center" ? (sw - w) / 2 : right - w;
            const y = pos[0] === "bottom" ? bottom - h : top;
            return Qt.rect(x - win.screenX, y - win.screenY, 1, 1);
        }
        implicitWidth: w
        implicitHeight: Math.max(1, notifStack.implicitHeight)
        color: "transparent"
        visible: Notifs.popups.length > 0 && win.screen === Panels.focusedScreen() && Panels.popup !== "qs"

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
