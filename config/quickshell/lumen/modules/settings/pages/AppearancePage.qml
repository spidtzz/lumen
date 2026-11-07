import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Page {
    title: "Appearance"
    description: "Colours, corners and text. Changes apply to the shell, apps and the login screen."

    readonly property var accents: [
        { id: "blue", label: "Blue", light: "#2867e4", dark: "#71a3ff" },
        { id: "violet", label: "Violet", light: "#7e4ed7", dark: "#ad8dfd" },
        { id: "teal", label: "Teal", light: "#00837e", dark: "#00bdb6" },
        { id: "green", label: "Green", light: "#00893d", dark: "#4ac06c" },
        { id: "orange", label: "Orange", light: "#ac5700", dark: "#ef852e" },
        { id: "pink", label: "Pink", light: "#c32777", dark: "#f075aa" },
        { id: "mono", label: "Mono", light: "#222222", dark: "#e4e4e4" }
    ]

    Card {
        title: "Style"
        SettingRow {
            label: "Mode"
            description: "Light or dark, for the shell and every app."
            Seg {
                options: [{ label: "Light", value: "light" }, { label: "Dark", value: "dark" }]
                value: Theme.mode
                onPicked: v => Theme.setValue("mode", v)
            }
        }
        SettingRow {
            label: "Corners"
            description: "Rounded or square, for the shell, windows, GTK apps and the login screen. Qt apps keep their own small corners."
            Seg {
                options: [{ label: "Rounded", value: "rounded" }, { label: "Square", value: "square" }]
                value: Theme.rounded ? "rounded" : "square"
                onPicked: v => Theme.setValue("corners", v)
            }
        }
        SettingRow {
            label: "Rounded screen corners"
            description: "Rounds the corners of the screen itself, like a phone or a MacBook."
            Toggle {
                checked: Theme.screenCorners
                onToggled: c => Theme.setValue("screen_corners", c)
            }
        }
    }

    Card {
        title: "Accent colour"
        description: "Used for selections, the focused window and highlights."

        // Fixed-size tiles, so choosing one never moves the others.
        Flow {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: accents
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    readonly property bool selected: Theme.accentName === modelData.id
                    readonly property color swatch: Theme.dark ? modelData.dark : modelData.light

                    width: 92
                    height: 88
                    radius: Theme.radiusSmall
                    color: selected ? Theme.field : tileHover.hovered ? Theme.field : "transparent"
                    border.width: selected ? 2 : 1
                    border.color: selected ? tile.swatch : Theme.line
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 14
                        width: 34
                        height: 34
                        radius: Theme.r(17)
                        color: tile.swatch
                        Icon {
                            anchors.centerIn: parent
                            visible: tile.selected
                            name: "check"
                            size: 18
                            stroke: 2.6
                            color: Theme.dark ? "#101010" : "#ffffff"
                        }
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        text: tile.modelData.label
                        size: 12
                        strong: true
                        muted: !tile.selected
                        wrapMode: Text.NoWrap
                    }
                    HoverHandler { id: tileHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Theme.setValue("accent", tile.modelData.id) }
                }
            }
        }
    }

    Card {
        title: "Text"
        SettingRow {
            label: "Text size"
            description: "For the shell and apps (" + Theme.fontFamily + ")."
            Btn {
                icon: "minus"
                enabled: Theme.fontSize > 8
                onClicked: Theme.setValue("font_size", Theme.fontSize - 1)
            }
            Txt {
                text: Theme.fontSize
                size: 18
                strong: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 32
            }
            Btn {
                icon: "plus"
                enabled: Theme.fontSize < 14
                onClicked: Theme.setValue("font_size", Theme.fontSize + 1)
            }
        }
    }

    Card {
        title: "Windows"
        SettingRow {
            label: "Highlight the focused window"
            description: Theme.conf.compositor === "false"
                ? "An accent outline. Always on while the compositor is off (Settings › Performance)."
                : Theme.rounded
                  ? "A soft accent glow around the window you're using (it follows the rounded corners). Off: other windows are slightly dimmed instead."
                  : "An accent outline around the window you're using. Off: other windows are slightly dimmed instead."
            Toggle {
                enabled: Theme.conf.compositor !== "false"
                checked: Theme.conf.window_border !== "false"
                onToggled: c => Theme.setValue("window_border", c)
            }
        }
        SettingRow {
            label: "Title-bar buttons"
            description: "Minimise, maximise and close buttons in apps that draw their own title bar. Off by default: close windows with super + Q. Open apps update after a restart."
            Toggle {
                checked: Theme.conf.window_buttons === "true"
                onToggled: c => Theme.setValue("window_buttons", c)
            }
        }
    }
}
