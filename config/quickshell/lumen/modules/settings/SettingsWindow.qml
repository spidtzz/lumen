import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// The Settings app: a normal window with a sidebar of pages.
// Open with super + comma, or `qs -c lumen ipc call settings open display`.
FloatingWindow {
    id: win

    title: "lumen Settings"
    implicitWidth: 1000
    implicitHeight: 680
    color: Theme.bg

    readonly property var pages: [
        { id: "appearance", label: "Appearance", icon: "droplet", file: "AppearancePage.qml" },
        { id: "bar", label: "Bar", icon: "layout", file: "BarPage.qml" },
        { id: "display", label: "Displays", icon: "monitor", file: "DisplayPage.qml" },
        { id: "sound", label: "Sound", icon: "volume", file: "SoundPage.qml" },
        { id: "network", label: "Network", icon: "wifi", file: "NetworkPage.qml" },
        { id: "input", label: "Keyboard & Mouse", icon: "keyboard", file: "InputPage.qml" },
        { id: "datetime", label: "Date & Time", icon: "clock", file: "DateTimePage.qml" },
        { id: "users", label: "Users", icon: "user", file: "UsersPage.qml" },
        { id: "about", label: "About", icon: "info", file: "AboutPage.qml" }
    ]
    readonly property var currentPage: pages.find(p => p.id === Panels.settingsPage) ?? pages[0]

    // Closing the window from bspwm (super + q) hides it; free it then.
    onVisibleChanged: if (!visible) Panels.settingsOpen = false

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Panels.settingsOpen = false
        Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
                const i = win.pages.indexOf(win.currentPage);
                if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Tab) {
                    Panels.settingsPage = win.pages[(i + 1) % win.pages.length].id;
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_Backtab) {
                    Panels.settingsPage = win.pages[(i + win.pages.length - 1) % win.pages.length].id;
                    event.accepted = true;
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ---- sidebar ----
            Rectangle {
                Layout.preferredWidth: 236
                Layout.fillHeight: true
                color: Theme.field

                Rectangle {   // divider
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.line
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        Layout.bottomMargin: 14
                        Layout.topMargin: 6
                        Layout.leftMargin: 6
                        spacing: 10
                        Avatar { size: 34 }
                        ColumnLayout {
                            spacing: 0
                            Txt { text: "Settings"; size: 18; strong: true }
                            Txt { text: Theme.userName; size: 12; muted: true }
                        }
                    }

                    Repeater {
                        model: win.pages
                        delegate: Rectangle {
                            id: item
                            required property var modelData
                            readonly property bool selected: modelData.id === win.currentPage.id

                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: Theme.radiusSmall
                            color: selected ? Theme.accent : hover.hovered ? Theme.panel : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12
                                Icon {
                                    name: item.modelData.icon
                                    size: 18
                                    color: item.selected ? Theme.accentFg : Theme.ink
                                }
                                Txt {
                                    Layout.fillWidth: true
                                    text: item.modelData.label
                                    strong: true
                                    color: item.selected ? Theme.accentFg : Theme.ink
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                }
                            }
                            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Panels.settingsPage = item.modelData.id }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Txt {
                        Layout.leftMargin: 6
                        text: "Esc to close · Ctrl+Tab next page"
                        size: 11
                        muted: true
                    }
                }
            }

            // ---- page ----
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: Qt.resolvedUrl("pages/" + win.currentPage.file)
                asynchronous: false
            }
        }
    }
}
