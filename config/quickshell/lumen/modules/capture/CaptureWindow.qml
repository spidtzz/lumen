import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// Screenshot and recording panel (Print): choose screenshot or recording,
// then the whole screen, the focused window or a selection.
// A normal window so it gets keyboard focus (bspwmrc rule "lumen Capture").
FloatingWindow {
    id: win

    title: "lumen Capture"
    implicitWidth: 460
    implicitHeight: card.implicitHeight
    color: Theme.panel

    property string mode: "shot"        // shot | record
    property string target: "screen"    // screen | window | selection
    property int delay: 0
    property bool copy: true
    property bool audio: false
    property bool cursor: true

    function close() { Panels.captureOpen = false; }
    function capture() {
        const cmd = mode === "shot"
            ? ["lumen-capture", "shot", target, "--delay", String(delay)].concat(copy ? [] : ["--no-copy"])
            : ["lumen-capture", "record", target].concat(audio ? ["--audio"] : []).concat(cursor ? [] : ["--no-cursor"]);
        close();   // the script waits a moment for this window to disappear
        Quickshell.execDetached(cmd);
    }

    Rectangle {
        id: card
        width: win.width
        implicitHeight: col.implicitHeight + 32
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        focus: true

        readonly property bool active: Window.active
        property bool wasActive: false
        onActiveChanged: {
            if (active) { wasActive = true; card.forceActiveFocus(); }
            else if (wasActive) win.close();
        }

        Keys.onEscapePressed: win.close()
        Keys.onReturnPressed: win.capture()
        Keys.onEnterPressed: win.capture()
        Keys.onPressed: event => {
            const t = { "1": "screen", "2": "window", "3": "selection" }[event.text];
            if (t) { win.target = t; event.accepted = true; }
            else if (event.key === Qt.Key_Tab) { win.mode = win.mode === "shot" ? "record" : "shot"; event.accepted = true; }
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 14

            Seg {
                Layout.fillWidth: true
                options: [{ label: "Screenshot", value: "shot" }, { label: "Record", value: "record" }]
                value: win.mode
                onPicked: v => win.mode = v
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [
                        { id: "screen", label: "Screen", icon: "monitor" },
                        { id: "window", label: "Window", icon: "layout" },
                        { id: "selection", label: "Selection", icon: "crop" }
                    ]
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool selected: win.target === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 86
                        radius: Theme.r(12)
                        color: selected ? Theme.accent : tileHover.hovered ? Theme.field : Theme.bg
                        border.width: 1
                        border.color: selected ? Theme.accent : Theme.line

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Icon { Layout.alignment: Qt.AlignHCenter; name: tile.modelData.icon; size: 24; color: tile.selected ? Theme.accentFg : Theme.ink }
                            Txt { Layout.alignment: Qt.AlignHCenter; text: tile.modelData.label; strong: true; size: 13; color: tile.selected ? Theme.accentFg : Theme.ink }
                        }
                        Txt {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 7
                            text: tile.index + 1
                            size: 10
                            color: tile.selected ? Theme.accentFg : Theme.muted
                        }
                        HoverHandler { id: tileHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: win.target = tile.modelData.id; onDoubleTapped: win.capture() }
                    }
                }
            }

            // ---- screenshot options ----
            SettingRow {
                visible: win.mode === "shot"
                label: "Delay"
                Seg {
                    implicitWidth: 220
                    options: [{ label: "None", value: 0 }, { label: "3 s", value: 3 }, { label: "5 s", value: 5 }, { label: "10 s", value: 10 }]
                    value: win.delay
                    onPicked: v => win.delay = v
                }
            }
            SettingRow {
                visible: win.mode === "shot"
                label: "Copy to the clipboard"
                Toggle { checked: win.copy; onToggled: c => win.copy = c }
            }

            // ---- recording options ----
            SettingRow {
                visible: win.mode === "record"
                label: "Record sound"
                description: "What your speakers play."
                Toggle { checked: win.audio; onToggled: c => win.audio = c }
            }
            SettingRow {
                visible: win.mode === "record"
                label: "Show the pointer"
                Toggle { checked: win.cursor; onToggled: c => win.cursor = c }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Txt {
                    Layout.fillWidth: true
                    text: win.mode === "shot" ? "Saved to Pictures/Screenshots" : "Saved to Videos/Recordings · stop from the bar"
                    size: 12
                    muted: true
                }
                Btn { text: "Cancel"; variant: "ghost"; onClicked: win.close() }
                Btn {
                    text: win.mode === "shot" ? "Take screenshot" : "Start recording"
                    icon: win.mode === "shot" ? "camera" : "record"
                    variant: "primary"
                    onClicked: win.capture()
                }
            }
        }
    }

    Component.onCompleted: card.forceActiveFocus()
}
