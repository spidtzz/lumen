import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// Emoji picker (super + .): opens next to the pointer on the tab you used
// last; type to search by name, arrows to move, Enter or a click copies the
// emoji (paste with ctrl + v). Recently used ones come first.
// A normal window so it gets the keyboard (bspwmrc rule "lumen Emoji";
// lumen-emoji place puts it at the pointer).
FloatingWindow {
    id: win

    title: "lumen Emoji"
    implicitWidth: 452
    implicitHeight: 470
    color: Theme.panel

    // The list ships with the shell's own files.
    readonly property string dataFile: Quickshell.shellDir + "/data/emoji.tsv"
    readonly property var groupNames: ["Recent", "Smileys", "People", "Animals & nature", "Food & drink", "Activities", "Travel & places", "Objects", "Symbols"]
    readonly property var groupIcons: ({ "Recent": "clock", "Smileys": "smile", "People": "user", "Animals & nature": "leaf",
        "Food & drink": "coffee", "Activities": "gamepad", "Travel & places": "plane", "Objects": "lightbulb", "Symbols": "heart" })

    property var all: []          // { e, name, group }
    // the tab you used last
    property string group: groupNames.includes(Theme.conf.emoji_group) ? Theme.conf.emoji_group
                         : recent.length > 0 ? "Recent" : "Smileys"
    function setGroup(g) {
        group = g;
        grid.currentIndex = 0;
        Theme.setValue("emoji_group", g);
    }

    // Recent emoji, stored as code points ("1f600 2764-fe0f") in settings.
    readonly property var recent: {
        const s = Theme.conf.emoji_recent || "";
        return s === "" ? [] : s.split(" ").filter(x => x !== "").map(x => String.fromCodePoint(...x.split("-").map(h => parseInt(h, 16))));
    }
    function codes(e) { return Array.from(e).map(c => c.codePointAt(0).toString(16)).join("-"); }

    readonly property string query: input.text.trim().toLowerCase()
    readonly property var shown: {
        if (query !== "") {
            const words = query.split(/\s+/);
            return all.filter(x => words.every(w => x.name.includes(w)));
        }
        if (group === "Recent") return recent.map(e => all.find(x => x.e === e) ?? { e: e, name: "", group: "" });
        return all.filter(x => x.group === group);
    }
    readonly property var current: shown[grid.currentIndex] ?? null

    function close() { Panels.emojiOpen = false; }
    function pick(item) {
        if (!item) return;
        const list = [codes(item.e)].concat((Theme.conf.emoji_recent || "").split(" ").filter(x => x !== "" && x !== codes(item.e))).slice(0, 32);
        Theme.setValue("emoji_recent", list.join(" "));
        close();
        Quickshell.execDetached(["lumen-emoji", "copy", item.e]);
    }
    function move(dx, dy) {
        if (shown.length === 0) return;
        const cols = Math.max(1, Math.floor(grid.width / grid.cellWidth));
        grid.currentIndex = Math.max(0, Math.min(shown.length - 1, grid.currentIndex + dx + dy * cols));
    }

    FileView {
        path: win.dataFile
        onLoaded: {
            win.all = text().split("\n").filter(l => l !== "").map(l => {
                const f = l.split("\t");
                return { e: f[0], name: f[1] || "", group: f[2] || "" };
            });
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        opacity: 0
        scale: 0.97
        NumberAnimation on opacity { to: 1; duration: Theme.animNormal; easing.type: Theme.easeOut }
        NumberAnimation on scale { to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }

        // Close when another window gets focus.
        readonly property bool active: Window.active
        property bool wasActive: false
        onActiveChanged: {
            if (active) { wasActive = true; input.forceActiveFocus(); }
            else if (wasActive) win.close();
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // ---- search ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.radiusSmall
                color: Theme.field
                border.width: 1
                border.color: input.activeFocus ? Theme.accent : Theme.line
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Icon { name: "search"; size: 16; color: Theme.muted }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(15 * Theme.fontScale)
                        color: Theme.ink
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentFg
                        clip: true
                        focus: true
                        onTextChanged: grid.currentIndex = 0
                        Keys.onLeftPressed: event => { if (text === "") win.move(-1, 0); else event.accepted = false; }
                        Keys.onRightPressed: event => { if (text === "") win.move(1, 0); else event.accepted = false; }
                        Keys.onUpPressed: win.move(0, -1)
                        Keys.onDownPressed: win.move(0, 1)
                        Keys.onReturnPressed: win.pick(win.current)
                        Keys.onEnterPressed: win.pick(win.current)
                        Keys.onEscapePressed: { if (text !== "") text = ""; else win.close(); }
                        Keys.onTabPressed: {
                            const i = win.groupNames.indexOf(win.group);
                            win.setGroup(win.groupNames[(i + 1) % win.groupNames.length]);
                        }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: "Search emoji"
                            muted: true
                        }
                    }
                }
            }

            // ---- groups ----
            RowLayout {
                visible: win.query === ""
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    model: win.groupNames
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool selected: win.group === modelData
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: Theme.radiusSmall
                        color: selected ? Theme.accent : tabHover.hovered ? Theme.field : "transparent"
                        Icon {
                            anchors.centerIn: parent
                            name: win.groupIcons[parent.modelData] || "smile"
                            size: 17
                            color: parent.selected ? Theme.accentFg : Theme.muted
                        }
                        HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: { win.setGroup(parent.modelData); input.forceActiveFocus(); } }
                    }
                }
            }

            // ---- emoji ----
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / 9)
                cellHeight: 46
                model: win.shown
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                currentIndex: 0
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: Theme.radiusSmall
                        color: grid.currentIndex === cell.index ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                             : cellHover.hovered ? Theme.field : "transparent"
                        border.width: grid.currentIndex === cell.index ? 1 : 0
                        border.color: Theme.accent
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.e
                        font.family: "emoji"   // fontconfig: your own emoji font (Apple, Twemoji, Noto...)
                        font.pixelSize: 26
                    }
                    HoverHandler {
                        id: cellHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) grid.currentIndex = cell.index
                    }
                    TapHandler { onTapped: win.pick(cell.modelData) }
                }
            }

            Txt {
                visible: win.shown.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: win.all.length === 0 ? "Couldn't read the emoji list (" + win.dataFile + ")."
                    : win.query !== "" ? "No emoji called “" + input.text + "”."
                    : win.group === "Recent" ? "Emoji you use show up here." : ""
                muted: true
            }

            // ---- the one under the cursor ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: win.current ? win.current.e : " "
                    font.family: "emoji"   // fontconfig: your own emoji font (Apple, Twemoji, Noto...)
                    font.pixelSize: 22
                }
                Txt {
                    Layout.fillWidth: true
                    text: win.current && win.current.name !== "" ? win.current.name : win.query === "" ? win.group : ""
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
                Txt { text: "Enter copies · Tab: next group"; muted: true; size: 11 }
            }
        }
    }
}
