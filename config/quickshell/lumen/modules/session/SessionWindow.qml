import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// Session menu (super + p, and the power button in quick settings): lock,
// log out, suspend, restart, shut down. A dimmed full-screen layer with a
// card in the middle; the last three ask first, in the same card.
// Keys: arrows or 1-5 choose, Enter confirms, Esc goes back or closes.
FloatingWindow {
    id: win

    title: "lumen Session"
    color: "transparent"
    implicitWidth: 1200
    implicitHeight: 800

    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "lock", ask: false, cmd: ["lumen-lock"] },
        { id: "logout", label: "Log out", icon: "log-out", ask: true, cmd: ["bspc", "quit"],
          question: "Log out now?", detail: "Apps that are open will close. Save your work first." },
        { id: "suspend", label: "Suspend", icon: "moon", ask: false, cmd: ["systemctl", "suspend"] },
        { id: "restart", label: "Restart", icon: "restart", ask: true, cmd: ["systemctl", "reboot"],
          question: "Restart now?", detail: "Apps that are open will close. Save your work first." },
        { id: "shutdown", label: "Shut down", icon: "power", ask: true, cmd: ["systemctl", "poweroff"],
          question: "Shut down now?", detail: "Apps that are open will close. Save your work first." }
    ]
    property int index: Math.max(0, actions.findIndex(a => a.id === Panels.sessionAction))
    // The action waiting for "yes" (opened straight here from quick settings,
    // or chosen in the menu).
    property var asking: actions.find(a => a.id === Panels.sessionAction && a.ask) ?? null
    // Opened straight at a question (from quick settings): Esc and Cancel
    // close the whole thing instead of showing the menu.
    readonly property bool direct: Panels.sessionAction !== ""
    function back() { if (direct) close(); else asking = null; }

    function close() { Panels.sessionOpen = false; }
    function choose(i) {
        const a = actions[i];
        if (!a) return;
        index = i;
        if (a.ask) asking = a;
        else run(a);
    }
    function run(a) {
        close();
        Quickshell.execDetached(a.cmd);
    }

    // Dim the desktop; click outside the card to close.
    Rectangle {
        id: shade
        anchors.fill: parent
        color: "#000000"
        opacity: 0
        NumberAnimation on opacity { to: 0.45; duration: Theme.animSlow; easing.type: Theme.easeOut }
        MouseArea { anchors.fill: parent; onClicked: win.close() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: win.asking ? 420 : row.implicitWidth + 48
        height: (win.asking ? ask.implicitHeight : menu.implicitHeight) + 48
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeInOut } }
        Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeInOut } }
        NumberAnimation on opacity { from: 0; to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }
        NumberAnimation on scale { from: 0.94; to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }
        clip: true
        MouseArea { anchors.fill: parent }   // clicks inside don't close

        focus: true
        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape) { win.asking ? win.back() : win.close(); }
            else if (win.asking) {
                if (k === Qt.Key_Return || k === Qt.Key_Enter) win.run(win.asking);
            } else if (k === Qt.Key_Left || k === Qt.Key_Up || k === Qt.Key_Backtab) {
                win.index = (win.index + win.actions.length - 1) % win.actions.length;
            } else if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab) {
                win.index = (win.index + 1) % win.actions.length;
            } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
                win.choose(win.index);
            } else if (k >= Qt.Key_1 && k <= Qt.Key_5) {
                win.choose(k - Qt.Key_1);
            } else return;
            event.accepted = true;
        }

        // Close when focus moves away (another window clicked).
        readonly property bool active: Window.active
        property bool wasActive: false
        onActiveChanged: {
            if (active) { wasActive = true; card.forceActiveFocus(); }
            else if (wasActive) win.close();
        }

        // ---- the menu ----
        ColumnLayout {
            id: menu
            anchors.centerIn: parent
            visible: !win.asking
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
            spacing: 18

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                Avatar { size: 30 }
                Txt { text: Theme.userName; size: 16; strong: true }
            }

            RowLayout {
                id: row
                spacing: 10
                Repeater {
                    model: win.actions
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool current: index === win.index

                        implicitWidth: 112
                        implicitHeight: 118
                        radius: Theme.radiusSmall + 3
                        color: current ? Theme.field : hover.hovered ? Theme.field : "transparent"
                        border.width: current ? 2 : 1
                        border.color: current ? (modelData.id === "shutdown" || modelData.id === "restart" ? Theme.danger : Theme.accent) : Theme.line
                        scale: press.pressed ? 0.96 : 1
                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 48; height: 48
                                radius: Theme.r(24)
                                color: tile.current ? (tile.modelData.id === "shutdown" || tile.modelData.id === "restart" ? Theme.danger : Theme.accent) : Theme.panel
                                border.width: tile.current ? 0 : 1
                                border.color: Theme.line
                                Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
                                Icon {
                                    anchors.centerIn: parent
                                    name: tile.modelData.icon
                                    size: 22
                                    color: !tile.current ? Theme.ink
                                         : tile.modelData.id === "shutdown" || tile.modelData.id === "restart" ? "#ffffff" : Theme.accentFg
                                }
                            }
                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.label
                                size: 13
                                strong: true
                                wrapMode: Text.NoWrap
                            }
                        }
                        Txt {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            text: tile.index + 1
                            size: 10
                            muted: true
                        }
                        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor; onHoveredChanged: if (hovered) win.index = tile.index }
                        TapHandler { id: press; onTapped: win.choose(tile.index) }
                    }
                }
            }

            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: "← → or 1–5 to choose · Enter · Esc to close"
                size: 11
                muted: true
            }
        }

        // ---- asking first ----
        ColumnLayout {
            id: ask
            anchors.centerIn: parent
            width: 420 - 48
            visible: win.asking !== null
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 56; height: 56
                radius: Theme.r(28)
                color: win.asking && win.asking.id === "logout" ? Theme.accent : Theme.danger
                Icon {
                    anchors.centerIn: parent
                    name: win.asking ? win.asking.icon : "power"
                    size: 26
                    color: win.asking && win.asking.id === "logout" ? Theme.accentFg : "#ffffff"
                }
            }
            Txt {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: win.asking ? win.asking.question : ""
                size: 20
                strong: true
            }
            Txt {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: win.asking ? win.asking.detail : ""
                size: 13
                muted: true
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8
                Btn {
                    Layout.fillWidth: true
                    text: "Cancel"
                    variant: "ghost"
                    onClicked: win.back()
                }
                Btn {
                    Layout.fillWidth: true
                    text: win.asking ? win.asking.label : ""
                    icon: win.asking ? win.asking.icon : ""
                    variant: win.asking && win.asking.id === "logout" ? "primary" : "danger"
                    onClicked: win.run(win.asking)
                }
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: win.direct ? "Enter to confirm · Esc to cancel" : "Enter to confirm · Esc to go back"
                size: 11
                muted: true
            }
        }
    }
}
