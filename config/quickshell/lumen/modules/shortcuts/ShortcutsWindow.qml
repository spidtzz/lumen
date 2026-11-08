import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import "../../components/Sxhkd.js" as Sxhkd

// Keyboard shortcuts (super + /), read live from your own
// ~/.config/sxhkd/sxhkdrc: edit that file and this list follows.
FloatingWindow {
    id: win

    title: "lumen Shortcuts"
    implicitWidth: 880
    implicitHeight: 620
    color: Theme.panel

    readonly property string file: Theme.configHome + "/sxhkd/sxhkdrc"
    property var rows: []
    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        if (q === "") return rows;
        return rows.filter(r => (r.desc + " " + r.command + " " + r.group + " " + r.keys.map(c => c.join(" ")).join(" "))
            .toLowerCase().includes(q));
    }
    readonly property var groups: [...new Set(shown.map(r => r.group))]

    function close() { Panels.shortcutsOpen = false; }

    FileView {
        id: rc
        path: win.file
        watchChanges: true
        onFileChanged: reload()
        onLoaded: win.rows = Sxhkd.parse(text())
        onLoadFailed: win.rows = []
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

        readonly property bool active: Window.active
        property bool wasActive: false
        onActiveChanged: {
            if (active) { wasActive = true; search.forceActiveFocus(); }
            else if (wasActive) win.close();
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Icon { name: "keyboard"; size: 22; color: Theme.accent }
                Txt { text: "Keyboard shortcuts"; size: 20; strong: true }
                Item { Layout.fillWidth: true }
                Field {
                    id: search
                    Layout.preferredWidth: 280
                    placeholderText: "Search shortcuts"
                    focus: true
                    Keys.onEscapePressed: text === "" ? win.close() : text = ""
                    Keys.onDownPressed: flick.contentY = Math.min(flick.contentY + 60, Math.max(0, flick.contentHeight - flick.height))
                    Keys.onUpPressed: flick.contentY = Math.max(0, flick.contentY - 60)
                }
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: content.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                // Two columns of groups.
                GridLayout {
                    id: content
                    width: flick.width - 14
                    columns: 2
                    columnSpacing: 20
                    rowSpacing: 18

                    Repeater {
                        model: win.groups
                        delegate: ColumnLayout {
                            id: group
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            spacing: 4

                            Txt {
                                text: group.modelData
                                size: 12
                                strong: true
                                color: Theme.accent
                                Layout.bottomMargin: 2
                            }

                            Repeater {
                                model: win.shown.filter(r => r.group === group.modelData)
                                delegate: Rectangle {
                                    id: row
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(36, rowLayout.implicitHeight + 10)
                                    radius: Theme.r(8)
                                    color: rowHover.hovered ? Theme.field : "transparent"

                                    RowLayout {
                                        id: rowLayout
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Txt {
                                            Layout.fillWidth: true
                                            text: row.modelData.desc !== "" ? row.modelData.desc : row.modelData.command
                                            size: 13
                                            muted: row.modelData.desc === ""
                                            font.family: row.modelData.desc === "" ? Theme.monoFamily : Theme.fontFamily
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                        }

                                        // Key chips; "then" between chord parts.
                                        Flow {
                                            Layout.maximumWidth: 230
                                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                            spacing: 4
                                            layoutDirection: Qt.RightToLeft
                                            Repeater {
                                                model: {
                                                    const out = [];
                                                    row.modelData.keys.forEach((chord, i) => {
                                                        if (i > 0) out.push({ sep: true, t: "then" });
                                                        chord.forEach((k, j) => {
                                                            if (j > 0) out.push({ sep: true, t: "+" });
                                                            out.push({ sep: false, t: k });
                                                        });
                                                    });
                                                    return out.reverse();
                                                }
                                                delegate: Item {
                                                    required property var modelData
                                                    implicitWidth: modelData.sep ? sepText.implicitWidth : chip.implicitWidth
                                                    implicitHeight: 24
                                                    Txt {
                                                        id: sepText
                                                        visible: parent.modelData.sep
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: parent.modelData.t
                                                        size: 11
                                                        muted: true
                                                    }
                                                    Rectangle {
                                                        id: chip
                                                        visible: !parent.modelData.sep
                                                        implicitWidth: keyText.implicitWidth + 14
                                                        height: 24
                                                        radius: Theme.r(6)
                                                        color: Theme.bg
                                                        border.width: 1
                                                        border.color: Theme.line
                                                        Txt {
                                                            id: keyText
                                                            anchors.centerIn: parent
                                                            text: parent.parent.modelData.t
                                                            size: 12
                                                            strong: true
                                                            wrapMode: Text.NoWrap
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    HoverHandler { id: rowHover }
                                    // The full command as a tooltip-like hint.
                                    ToolTip.visible: rowHover.hovered && row.modelData.desc !== "" && row.modelData.command !== ""
                                    ToolTip.delay: 600
                                    ToolTip.text: row.modelData.command
                                }
                            }
                        }
                    }
                }

                Txt {
                    anchors.centerIn: parent
                    visible: win.shown.length === 0
                    text: win.rows.length === 0 ? "Couldn't read " + win.file.replace(Theme.home, "~") : "No shortcuts match."
                    muted: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Txt {
                    Layout.fillWidth: true
                    text: win.rows.length + " shortcuts from " + win.file.replace(Theme.home, "~") + "  ·  updates when you save the file"
                    size: 11
                    muted: true
                }
                Btn {
                    text: "Edit shortcuts"
                    variant: "ghost"
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", "sh", "-c", "${EDITOR:-vi} \"$1\"; pkill -USR1 -x sxhkd", "sh", win.file]);
                        win.close();
                    }
                }
            }
        }
    }

    Component.onCompleted: search.forceActiveFocus()
}
