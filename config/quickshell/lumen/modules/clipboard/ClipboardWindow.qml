import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// Clipboard history (super + v): search on top, entries on the left, a full
// preview of the selected one on the right (whole text, or the image).
// Enter copies it back, Delete removes it, Esc (or clicking elsewhere) closes.
// A normal window so bspwm gives it keyboard focus (bspwmrc rule
// "lumen Clipboard": floating, centred, borderless, on top).
FloatingWindow {
    id: win

    title: "lumen Clipboard"
    implicitWidth: 860
    implicitHeight: 500
    color: Theme.panel

    readonly property string dir: (Quickshell.env("XDG_CACHE_HOME") || (Theme.home + "/.cache")) + "/lumen/clipboard/"
    property var entries: []   // { id, type, size, preview }
    readonly property var shown: {
        const q = input.text.trim().toLowerCase();
        if (q === "") return entries;
        return entries.filter(e => e.type === "image" ? "image picture".includes(q) || q === "img" : e.preview.toLowerCase().includes(q));
    }
    readonly property var current: shown[list.currentIndex] ?? null

    function close() { Panels.clipboardOpen = false; }
    function refresh() { lister.running = true; }
    function move(n) {
        if (shown.length === 0) return;
        list.currentIndex = Math.max(0, Math.min(shown.length - 1, list.currentIndex + n));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }
    function copyCurrent() {
        if (!current) return;
        Quickshell.execDetached(["lumen-clipboard", "copy", current.id]);
        close();
    }
    function deleteCurrent() {
        if (!current) return;
        Quickshell.execDetached(["lumen-clipboard", "delete", current.id]);
        entries = entries.filter(e => e.id !== current.id);
    }
    function sizeLabel(n) {
        return n >= 1048576 ? (n / 1048576).toFixed(1) + " MB" : n >= 1024 ? Math.round(n / 1024) + " KB" : n + " B";
    }
    function timeLabel(id) {
        const t = new Date(Number(id.split(".")[0].slice(0, 13)));
        const mins = Math.floor((Date.now() - t.getTime()) / 60000);
        if (mins < 1) return "just now";
        if (mins < 60) return mins + " min ago";
        if (mins < 1440) return Math.floor(mins / 60) + " h ago";
        return t.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
    }

    Connections {
        target: Panels
        function onClipboardRevisionChanged() { win.refresh(); }
    }

    Process {
        id: lister
        command: ["lumen-clipboard", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const keep = win.current ? win.current.id : "";
                win.entries = text.split("\n").filter(l => l !== "").map(l => {
                    const f = l.split("\t");
                    return { id: f[0], type: f[1], size: +f[2], preview: f.slice(3).join("\t") };
                });
                const i = win.shown.findIndex(e => e.id === keep);
                list.currentIndex = Math.max(0, i);
            }
        }
    }

    // Full text of the selected entry.
    FileView {
        id: textFile
        path: win.current && win.current.type === "text" ? win.dir + win.current.id : ""
        blockLoading: false
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        // Arrives with a short, eased fade and grow.
        NumberAnimation on opacity { from: 0; to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }
        NumberAnimation on scale { from: 0.96; to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }
        border.width: 1
        border.color: Theme.line

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
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                spacing: 12
                Icon { name: "copy"; size: 20; color: Theme.muted }
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(18 * Theme.fontScale)
                    color: Theme.ink
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentFg
                    clip: true
                    focus: true
                    onTextChanged: { list.currentIndex = 0; list.positionViewAtBeginning(); }
                    Keys.onUpPressed: win.move(-1)
                    Keys.onDownPressed: win.move(1)
                    Keys.onReturnPressed: win.copyCurrent()
                    Keys.onEnterPressed: win.copyCurrent()
                    Keys.onEscapePressed: win.close()
                    Keys.onDeletePressed: event => {
                        // Delete removes the entry; in a search, it edits the text.
                        if (text === "") win.deleteCurrent(); else event.accepted = false;
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_PageDown) { win.move(6); event.accepted = true; }
                        else if (event.key === Qt.Key_PageUp) { win.move(-6); event.accepted = true; }
                    }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search clipboard history"
                        size: 18
                        muted: true
                        visible: input.text.length === 0
                    }
                }
                Btn {
                    text: "Clear all"
                    variant: "ghost"
                    enabled: win.entries.length > 0
                    onClicked: {
                        Quickshell.execDetached(["lumen-clipboard", "clear"]);
                        win.entries = [];
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }

            // ---- list + preview ----
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ListView {
                    id: list
                    Layout.preferredWidth: 330
                    Layout.fillHeight: true
                    clip: true
                    model: win.shown
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === list.currentIndex

                        width: list.width - 8
                        height: 54
                        radius: Theme.r(10)
                        color: selected ? Theme.accent : rowHover.hovered ? Theme.field : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 10

                            Rectangle {
                                implicitWidth: 34
                                implicitHeight: 34
                                radius: Theme.r(8)
                                color: row.selected ? Theme.accentFg : Theme.field
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    visible: row.modelData.type === "image"
                                    source: row.modelData.type === "image" ? "file://" + win.dir + row.modelData.id : ""
                                    sourceSize: Qt.size(68, 68)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    visible: row.modelData.type !== "image"
                                    name: "copy"
                                    size: 16
                                    color: row.selected ? Theme.accent : Theme.muted
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Txt {
                                    Layout.fillWidth: true
                                    text: row.modelData.type === "image" ? "Image" : row.modelData.preview
                                    strong: row.modelData.type === "image"
                                    size: 13
                                    color: row.selected ? Theme.accentFg : Theme.ink
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                }
                                Txt {
                                    text: win.timeLabel(row.modelData.id) + "  ·  " + win.sizeLabel(row.modelData.size)
                                    size: 11
                                    color: row.selected ? Theme.accentFg : Theme.muted
                                    opacity: row.selected ? 0.85 : 1
                                }
                            }

                            Rectangle {
                                visible: rowHover.hovered
                                width: 26; height: 26; radius: Theme.r(13)
                                color: trashHover.hovered ? (row.selected ? Theme.accentFg : Theme.line) : "transparent"
                                Icon {
                                    anchors.centerIn: parent
                                    name: "trash"
                                    size: 14
                                    color: trashHover.hovered && row.selected ? Theme.accent : row.selected ? Theme.accentFg : Theme.muted
                                }
                                HoverHandler { id: trashHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: {
                                        list.currentIndex = row.index;
                                        win.deleteCurrent();
                                    }
                                }
                            }
                        }

                        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: list.currentIndex = row.index
                            onDoubleTapped: { list.currentIndex = row.index; win.copyCurrent(); }
                        }
                    }

                    Txt {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        horizontalAlignment: Text.AlignHCenter
                        visible: win.shown.length === 0
                        text: win.entries.length === 0
                            ? (Theme.conf.clipboard_history === "false" ? "Clipboard history is off (Settings › Users)." : "Nothing copied yet.")
                            : "No matches."
                        muted: true
                    }
                }

                // ---- preview ----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusSmall
                    color: Theme.field
                    border.width: 1
                    border.color: Theme.line
                    clip: true

                    Image {
                        id: preview
                        anchors.fill: parent
                        anchors.margins: 12
                        visible: win.current !== null && win.current.type === "image"
                        source: visible ? "file://" + win.dir + win.current.id : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize: Qt.size(1000, 1000)
                    }
                    Txt {
                        visible: preview.visible && preview.status === Image.Ready
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 10
                        text: preview.implicitWidth + " × " + preview.implicitHeight
                        size: 11
                        muted: true
                    }

                    Flickable {
                        id: textFlick
                        anchors.fill: parent
                        anchors.margins: 12
                        visible: win.current !== null && win.current.type === "text"
                        contentWidth: width
                        contentHeight: fullText.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        TextEdit {
                            id: fullText
                            width: textFlick.width - 12
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.PlainText
                            color: Theme.ink
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentFg
                            font.family: Theme.monoFamily
                            font.pixelSize: Math.round(13 * Theme.fontScale)
                            // Very long text: show the start (the full text is still copied).
                            text: {
                                const t = textFile.loaded ? textFile.text() : "";
                                return t.length > 20000 ? t.slice(0, 20000) + "\n\n… (" + win.sizeLabel(win.current.size) + " in total)" : t;
                            }
                        }
                    }

                    Txt {
                        anchors.centerIn: parent
                        visible: win.current === null
                        text: "Select an entry to preview it"
                        muted: true
                    }
                }
            }

            Txt {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                text: win.entries.length + (win.entries.length === 1 ? " entry" : " entries") + "   ↑↓ move · Enter copy · Delete remove · Esc close"
                size: 11
                muted: true
            }
        }
    }

    // Like the launcher: don't let focus-follows-mouse close it.
    Component.onCompleted: {
        input.forceActiveFocus();
        Quickshell.execDetached(["bspc", "config", "focus_follows_pointer", "false"]);
    }
    Component.onDestruction: {
        if (Theme.conf.focus_follows_mouse !== "false")
            Quickshell.execDetached(["bspc", "config", "focus_follows_pointer", "true"]);
    }
}
