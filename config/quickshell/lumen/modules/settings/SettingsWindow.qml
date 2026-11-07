import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// The Settings app: a normal window with a sidebar of pages.
// Open with super + i, `lumen settings`, or `lumen settings display`.
FloatingWindow {
    id: win

    title: "lumen Settings"
    implicitWidth: 1000
    implicitHeight: 720
    color: Theme.bg

    // Pages, grouped into sections in the sidebar.
    readonly property var pages: [
        { id: "network", section: "Connections", label: "Network", icon: "wifi", file: "NetworkPage.qml" },
        { id: "bluetooth", section: "Connections", label: "Bluetooth", icon: "bluetooth", file: "BluetoothPage.qml" },
        { id: "appearance", section: "Personalisation", label: "Appearance", icon: "droplet", file: "AppearancePage.qml" },
        { id: "wallpaper", section: "Personalisation", label: "Wallpaper", icon: "image", file: "WallpaperPage.qml" },
        { id: "bar", section: "Personalisation", label: "Bar", icon: "layout", file: "BarPage.qml" },
        { id: "display", section: "Devices", label: "Displays", icon: "monitor", file: "DisplayPage.qml" },
        { id: "sound", section: "Devices", label: "Sound", icon: "volume", file: "SoundPage.qml" },
        { id: "input", section: "Devices", label: "Keyboard & Mouse", icon: "keyboard", file: "InputPage.qml" },
        { id: "notifications", section: "System", label: "Notifications", icon: "bell", file: "NotificationsPage.qml" },
        { id: "performance", section: "System", label: "Performance", icon: "cpu", file: "PerformancePage.qml" },
        { id: "datetime", section: "System", label: "Date & Time", icon: "clock", file: "DateTimePage.qml" },
        { id: "users", section: "System", label: "Users & Privacy", icon: "user", file: "UsersPage.qml" },
        { id: "about", section: "System", label: "About", icon: "info", file: "AboutPage.qml" }
    ]
    readonly property var sections: [...new Set(pages.map(p => p.section))]
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
                        // The lumen logo, as on the app launcher button.
                        Rectangle {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: Theme.r(17)
                            color: Theme.accent
                            Icon {
                                anchors.centerIn: parent
                                name: "lumen"
                                size: 22
                                stroke: 2.2
                                color: Theme.accentFg
                            }
                        }
                        Txt { text: "Settings"; size: 18; strong: true }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: sectionsCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: sectionsCol
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: win.sections
                                delegate: ColumnLayout {
                                    id: section
                                    required property string modelData
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Txt {
                                        Layout.topMargin: 10
                                        Layout.leftMargin: 12
                                        Layout.bottomMargin: 2
                                        text: section.modelData
                                        size: 11
                                        strong: true
                                        muted: true
                                    }

                                    Repeater {
                                        model: win.pages.filter(p => p.section === section.modelData)
                                delegate: Rectangle {
                                    id: item
                                    required property var modelData
                                    readonly property bool selected: modelData.id === win.currentPage.id

                                    Layout.fillWidth: true
                                    implicitHeight: 36
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
                                }
                            }
                        }
                    }


                    Btn {
                        Layout.fillWidth: true
                        text: "Quit Settings"
                        icon: "x"
                        variant: "ghost"
                        onClicked: Panels.settingsOpen = false
                    }
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
