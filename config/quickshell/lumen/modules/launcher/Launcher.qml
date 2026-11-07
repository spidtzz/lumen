import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

// Spotlight-style app launcher. Five results show at once; the mouse wheel
// scrolls smoothly, arrow keys move one row at a time.
// Enter opens, Esc (or clicking anywhere else) closes.
// It's a normal window so bspwm gives it keyboard focus; the bspwmrc rule for
// "lumen Launcher" makes it floating, centred, borderless and on top.
FloatingWindow {
    id: win

    title: "lumen Launcher"
    implicitWidth: 640
    implicitHeight: card.height
    color: Theme.panel

    readonly property int rowHeight: 58
    readonly property int visibleRows: 5
    property var results: Apps.search("")

    function close() { Panels.launcherOpen = false; }
    function launch(i) {
        const e = results[i];
        if (!e) return;
        close();
        Apps.launch(e);
    }
    function move(n) {
        if (results.length === 0) return;
        list.currentIndex = Math.max(0, Math.min(results.length - 1, list.currentIndex + n));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);   // jump, no animation
    }

    Rectangle {
        id: card
        width: win.width
        height: col.implicitHeight + 20
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.line

        // Close when another window gets focus (a click elsewhere).
        readonly property bool active: Window.active
        property bool wasActive: false
        onActiveChanged: {
            if (active) { wasActive = true; input.forceActiveFocus(); }
            else if (wasActive) win.close();
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            // ---- search ----
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 4
                spacing: 12
                Icon { name: "search"; size: 22; color: Theme.muted }
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(22 * Theme.fontScale)
                    font.weight: Font.Medium
                    color: Theme.ink
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentFg
                    clip: true
                    focus: true
                    onTextChanged: {
                        win.results = Apps.search(text);
                        list.currentIndex = 0;
                        list.positionViewAtBeginning();
                    }
                    Keys.onUpPressed: win.move(-1)
                    Keys.onDownPressed: win.move(1)
                    Keys.onTabPressed: win.move(1)
                    Keys.onBacktabPressed: win.move(-1)
                    Keys.onReturnPressed: win.launch(list.currentIndex)
                    Keys.onEnterPressed: win.launch(list.currentIndex)
                    Keys.onEscapePressed: win.close()
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_PageDown) { win.move(win.visibleRows); event.accepted = true; }
                        else if (event.key === Qt.Key_PageUp) { win.move(-win.visibleRows); event.accepted = true; }
                    }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search apps"
                        size: 22
                        muted: true
                        visible: input.text.length === 0
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }

            // ---- results ----
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: win.rowHeight * win.visibleRows
                clip: true
                model: win.results
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                interactive: true
                ScrollBar.vertical: ScrollBar { policy: list.contentHeight > list.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }

                // Smooth wheel scrolling: animate toward the target position.
                NumberAnimation { id: scrollAnim; target: list; property: "contentY"; duration: 220; easing.type: Easing.OutCubic }
                WheelHandler {
                    onWheel: event => {
                        const max = Math.max(0, list.contentHeight - list.height);
                        const from = scrollAnim.running ? scrollAnim.to : list.contentY;
                        scrollAnim.stop();
                        scrollAnim.to = Math.max(0, Math.min(max, from - event.angleDelta.y * 0.9));
                        scrollAnim.start();
                    }
                }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: index === list.currentIndex

                    width: list.width
                    height: win.rowHeight
                    radius: Theme.r(12)
                    color: current ? Theme.accent : rowHover.hovered ? Theme.field : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 14
                        spacing: 14

                        Item {
                            implicitWidth: 36
                            implicitHeight: 36
                            IconImage {
                                id: appIcon
                                anchors.fill: parent
                                source: Quickshell.iconPath(row.modelData.icon, true)
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.r(10)
                                visible: !appIcon.visible
                                color: row.current ? Theme.accentFg : Theme.field
                                Icon { anchors.centerIn: parent; name: "app"; size: 18; color: row.current ? Theme.accent : Theme.muted }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Txt {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                strong: true
                                size: 15
                                color: row.current ? Theme.accentFg : Theme.ink
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }
                            Txt {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.genericName || row.modelData.comment || ""
                                size: 12
                                color: row.current ? Theme.accentFg : Theme.muted
                                opacity: row.current ? 0.85 : 1
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }
                        }

                        Txt {
                            visible: row.current
                            text: "Enter ↵"
                            size: 11
                            color: Theme.accentFg
                            opacity: 0.8
                        }
                    }

                    HoverHandler {
                        id: rowHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler { onTapped: win.launch(row.index) }
                }

                Txt {
                    anchors.centerIn: parent
                    visible: win.results.length === 0
                    text: "No apps match “" + input.text + "”"
                    muted: true
                }
            }

            Txt {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.bottomMargin: 2
                text: win.results.length + (win.results.length === 1 ? " app" : " apps") + "   ↑↓ move · Enter open · Esc close"
                size: 11
                muted: true
            }
        }
    }

    // With focus-follows-mouse, nudging the mouse onto another window would
    // move focus and close the launcher; pause it while the launcher is open.
    Component.onCompleted: {
        input.forceActiveFocus();
        Quickshell.execDetached(["bspc", "config", "focus_follows_pointer", "false"]);
    }
    Component.onDestruction: {
        if (Theme.conf.focus_follows_mouse !== "false")
            Quickshell.execDetached(["bspc", "config", "focus_follows_pointer", "true"]);
    }
}
