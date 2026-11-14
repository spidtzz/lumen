import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import "../../components/Sxhkd.js" as Sxhkd

// Keyboard shortcuts (super + /), read live from ~/.config/sxhkd/sxhkdrc and
// your own ~/.config/lumen/keys: edit either and this list follows. Your keys
// come first and hide lumen's on the same keys (sxhkd uses yours).
//
// Groups down the left (click one to see only it), search on top (searches
// everything), and each shortcut as a row: what it does, the command under
// it, and its keys drawn as keys.
FloatingWindow {
    id: win

    title: "lumen Shortcuts"
    implicitWidth: 940
    implicitHeight: 660
    color: Theme.panel

    readonly property string file: Theme.configHome + "/sxhkd/sxhkdrc"
    readonly property string userFile: Theme.configHome + "/lumen/keys"
    property var lumenRows: []
    property var userRows: []
    readonly property var rows: {
        const key = r => JSON.stringify(r.keys);
        const mine = new Set(userRows.map(key));
        return userRows.concat(lumenRows.filter(r => !mine.has(key(r))));
    }

    // Search: every group. Otherwise the group picked on the left ("" = all).
    property string group: ""
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var matching: query === "" ? rows : rows.filter(r =>
        (r.desc + " " + r.command + " " + r.group + " " + r.keys.map(c => c.join(" ")).join(" ")).toLowerCase().includes(query))
    readonly property var groups: [...new Set(rows.map(r => r.group))]
    readonly property var shown: query !== "" || group === "" ? matching : matching.filter(r => r.group === group)
    readonly property var shownGroups: [...new Set(shown.map(r => r.group))]

    function close() { Panels.shortcutsOpen = false; }
    function count(g) { return matching.filter(r => r.group === g).length; }
    // Open a file in the terminal's editor; sxhkd reloads when it's closed.
    function edit(path) {
        Quickshell.execDetached(["kitty", "-e", "sh", "-c", "${EDITOR:-vi} \"$1\"; pkill -USR1 -x sxhkd", "sh", path]);
        close();
    }

    FileView {
        path: win.file
        watchChanges: true
        onFileChanged: reload()
        onLoaded: win.lumenRows = Sxhkd.parse(text())
        onLoadFailed: win.lumenRows = []
    }
    FileView {
        path: win.userFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: win.userRows = Sxhkd.parse(text(), "Your shortcuts")
        onLoadFailed: win.userRows = []
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        // Arrives with a short, eased fade and grow.
        NumberAnimation on opacity { from: 0; to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }
        NumberAnimation on scale { from: 0.97; to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }

        readonly property bool active: Window.active
        property bool wasActive: false
        onActiveChanged: {
            if (active) { wasActive = true; search.forceActiveFocus(); }
            else if (wasActive) win.close();
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            // ---- left: groups ----
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 210
                color: Theme.bg
                radius: Theme.radius
                // square off the inner edge
                Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 2

                    RowLayout {
                        spacing: 10
                        Layout.bottomMargin: 14
                        Layout.leftMargin: 4
                        Rectangle {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: Theme.r(10)
                            color: Theme.accent
                            Icon { anchors.centerIn: parent; name: "keyboard"; size: 18; color: Theme.accentFg }
                        }
                        ColumnLayout {
                            spacing: 0
                            Txt { text: "Shortcuts"; size: 16; strong: true }
                            Txt { text: win.rows.length + " in all"; size: 11; muted: true }
                        }
                    }

                    Repeater {
                        model: [""].concat(win.groups)
                        delegate: Rectangle {
                            id: gRow
                            required property string modelData
                            readonly property bool picked: win.query === "" && win.group === modelData
                            readonly property int n: modelData === "" ? win.matching.length : win.count(modelData)
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Theme.r(8)
                            color: picked ? Theme.field : gHover.hovered ? Qt.rgba(Theme.field.r, Theme.field.g, Theme.field.b, 0.6) : "transparent"
                            opacity: n === 0 ? 0.4 : 1

                            // the picked group's accent mark
                            Rectangle {
                                visible: gRow.picked
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 16
                                radius: 2
                                color: Theme.accent
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                Txt {
                                    Layout.fillWidth: true
                                    text: gRow.modelData === "" ? "All shortcuts" : gRow.modelData
                                    size: 13
                                    strong: gRow.picked
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                }
                                Txt { text: gRow.n; size: 11; muted: true; font.features: ({ "tnum": 1 }) }
                            }
                            HoverHandler { id: gHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    search.text = "";
                                    win.group = gRow.modelData;
                                    flick.contentY = 0;
                                    search.forceActiveFocus();
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Your own shortcuts live in a file updates never touch.
                    Btn {
                        Layout.fillWidth: true
                        icon: "plus"
                        text: "Add your own"
                        onClicked: win.edit(win.userFile)
                    }
                    Btn {
                        Layout.fillWidth: true
                        icon: "terminal"
                        text: "lumen's shortcuts"
                        variant: "ghost"
                        onClicked: win.edit(win.file)
                    }
                }
            }

            // ---- right: search and the list ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Txt {
                        Layout.fillWidth: true
                        text: win.query !== "" ? "Results" : win.group === "" ? "All shortcuts" : win.group
                        size: 20
                        strong: true
                        elide: Text.ElideRight
                    }
                    Field {
                        id: search
                        Layout.preferredWidth: 300
                        placeholderText: "Search by action, key or command"
                        leftPadding: 34
                        focus: true
                        Icon { x: 11; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 15; color: Theme.muted }
                        Keys.onEscapePressed: text === "" ? win.close() : text = ""
                        Keys.onDownPressed: flick.contentY = Math.min(flick.contentY + 60, Math.max(0, flick.contentHeight - flick.height))
                        Keys.onUpPressed: flick.contentY = Math.max(0, flick.contentY - 60)
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_PageDown) { flick.contentY = Math.min(flick.contentY + flick.height, Math.max(0, flick.contentHeight - flick.height)); e.accepted = true; }
                            else if (e.key === Qt.Key_PageUp) { flick.contentY = Math.max(0, flick.contentY - flick.height); e.accepted = true; }
                        }
                        onTextChanged: flick.contentY = 0
                    }
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: list
                        width: flick.width - 12
                        spacing: 18

                        Repeater {
                            model: win.shownGroups
                            delegate: ColumnLayout {
                                id: section
                                required property string modelData
                                readonly property var items: win.shown.filter(r => r.group === modelData)
                                Layout.fillWidth: true
                                spacing: 6

                                // Group title (only when showing more than one).
                                Txt {
                                    visible: win.shownGroups.length > 1 || win.query !== ""
                                    text: section.modelData
                                    size: 12
                                    strong: true
                                    color: Theme.accent
                                    Layout.leftMargin: 4
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: rowsCol.implicitHeight + 8
                                    radius: Theme.r(12)
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Theme.line

                                    ColumnLayout {
                                        id: rowsCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 4
                                        spacing: 0

                                        Repeater {
                                            model: section.items
                                            delegate: Rectangle {
                                                id: row
                                                required property var modelData
                                                required property int index
                                                readonly property bool hasDesc: modelData.desc !== ""
                                                Layout.fillWidth: true
                                                implicitHeight: Math.max(48, rowLayout.implicitHeight + 16)
                                                radius: Theme.r(8)
                                                color: rowHover.hovered ? Theme.field : "transparent"

                                                // divider between rows
                                                Rectangle {
                                                    visible: row.index > 0
                                                    anchors.top: parent.top
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 12
                                                    height: 1
                                                    color: Theme.line
                                                    opacity: rowHover.hovered ? 0 : 0.6
                                                }

                                                RowLayout {
                                                    id: rowLayout
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 10
                                                    spacing: 16

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2
                                                        Txt {
                                                            Layout.fillWidth: true
                                                            text: row.hasDesc ? row.modelData.desc : row.modelData.command
                                                            size: 13
                                                            strong: row.hasDesc
                                                            font.family: row.hasDesc ? Theme.fontFamily : Theme.monoFamily
                                                            elide: Text.ElideRight
                                                            wrapMode: Text.NoWrap
                                                        }
                                                        Txt {
                                                            visible: row.hasDesc && row.modelData.command !== ""
                                                            Layout.fillWidth: true
                                                            text: row.modelData.command
                                                            size: 11
                                                            muted: true
                                                            font.family: Theme.monoFamily
                                                            elide: Text.ElideRight
                                                            wrapMode: Text.NoWrap
                                                        }
                                                    }

                                                    // The keys; "then" between the parts of a chain,
                                                    // "or" between alternatives.
                                                    Flow {
                                                        Layout.maximumWidth: 360
                                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                                        spacing: 4
                                                        layoutDirection: Qt.RightToLeft
                                                        Repeater {
                                                            model: {
                                                                const out = [];
                                                                row.modelData.keys.forEach((chord, i) => {
                                                                    if (i > 0) out.push({ sep: "then" });
                                                                    chord.forEach((k, j) => {
                                                                        if (j > 0) out.push({ sep: "+" });
                                                                        String(k).split(" / ").forEach((alt, a) => {
                                                                            if (a > 0) out.push({ sep: "/" });
                                                                            out.push({ key: alt });
                                                                        });
                                                                    });
                                                                });
                                                                return out.reverse();
                                                            }
                                                            delegate: Item {
                                                                required property var modelData
                                                                implicitWidth: modelData.sep !== undefined ? sepText.implicitWidth + 2 : keyCap.implicitWidth
                                                                implicitHeight: 28
                                                                Txt {
                                                                    id: sepText
                                                                    visible: parent.modelData.sep !== undefined
                                                                    anchors.centerIn: parent
                                                                    text: parent.modelData.sep || ""
                                                                    size: 11
                                                                    muted: true
                                                                }
                                                                KeyCap {
                                                                    id: keyCap
                                                                    visible: parent.modelData.key !== undefined
                                                                    key: parent.modelData.key || ""
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                HoverHandler { id: rowHover }
                                                // The whole command, when it doesn't fit.
                                                ToolTip.visible: rowHover.hovered && row.modelData.command.length > 60
                                                ToolTip.delay: 700
                                                ToolTip.text: row.modelData.command
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Nothing to show.
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: win.shown.length === 0
                        spacing: 8
                        Icon { Layout.alignment: Qt.AlignHCenter; name: "search"; size: 30; color: Theme.muted; opacity: 0.6 }
                        Txt {
                            Layout.alignment: Qt.AlignHCenter
                            text: win.rows.length === 0 ? "Couldn't read " + win.file.replace(Theme.home, "~") : "No shortcuts match “" + search.text.trim() + "”"
                            muted: true
                        }
                    }
                }

                Txt {
                    Layout.fillWidth: true
                    text: "Type to search  ·  ↑ ↓ to scroll  ·  Esc to close  ·  Updates as soon as a file is saved"
                    size: 11
                    muted: true
                }
            }
        }
    }

    Component.onCompleted: search.forceActiveFocus()
}
