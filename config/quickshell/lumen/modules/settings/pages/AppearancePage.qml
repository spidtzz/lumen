import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

Page {
    title: "Appearance"
    description: "Colours, corners and text. Changes apply to the shell, apps and the login screen."

    // The accents of Pane, same values (share/palettes, tools/gen-palettes.py).
    readonly property var accents: [
        { id: "blue", label: "Blue", light: "#2867e4", dark: "#71a3ff" },
        { id: "violet", label: "Violet", light: "#7e4ed7", dark: "#ad8dfd" },
        { id: "teal", label: "Teal", light: "#007470", dark: "#00bdb6" },
        { id: "green", label: "Green", light: "#277a40", dark: "#4ac06c" },
        { id: "orange", label: "Orange", light: "#ac5700", dark: "#ef852e" },
        { id: "pink", label: "Pink", light: "#c32777", dark: "#f075aa" },
        { id: "red", label: "Red", light: "#cc272e", dark: "#f97770" },
        { id: "amber", label: "Amber", light: "#8a6700", dark: "#cf9c00" },
        { id: "lime", label: "Lime", light: "#587500", dark: "#8eb533" },
        { id: "cyan", label: "Cyan", light: "#007386", dark: "#00b8d6" },
        { id: "sky", label: "Sky", light: "#0573aa", dark: "#19affe" },
        { id: "indigo", label: "Indigo", light: "#5c5be2", dark: "#9099ff" },
        { id: "fuchsia", label: "Fuchsia", light: "#a839b0", dark: "#d67edb" },
        { id: "mono", label: "Mono", light: "#222222", dark: "#e4e4e4" }
    ]

    Card {
        title: "Style"
        SettingRow {
            label: "Mode"
            description: "For the shell and every app. Black is dark on pure black (for OLED screens)."
            Seg {
                options: [{ label: "Light", value: "light" }, { label: "Dark", value: "dark" }, { label: "Black", value: "black" }]
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
        readonly property bool autoAccent: Theme.conf.accent_auto === "true"
        readonly property bool hasPicture: (Theme.conf.wallpaper || "") !== ""
        description: autoAccent
            ? "Automatic: " + (accents.find(a => a.id === Theme.accentName) || { label: Theme.accentName }).label
              + ", the closest to your wallpaper's main colour. It changes with the wallpaper."
            : "Used for selections, the focused window and highlights."

        // Fixed-size tiles, so choosing one never moves the others.
        Flow {
            id: accentFlow
            Layout.fillWidth: true
            spacing: 10

            // Automatic: picked from the wallpaper (needs a picture).
            Rectangle {
                id: autoTile
                readonly property bool selected: Theme.conf.accent_auto === "true"
                width: 92
                height: 88
                radius: Theme.radiusSmall
                opacity: (Theme.conf.wallpaper || "") !== "" ? 1 : 0.45
                color: selected || autoHover.hovered ? Theme.field : "transparent"
                border.width: selected ? 2 : 1
                border.color: selected ? Theme.accent : Theme.line
                Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 14
                    width: 34
                    height: 34
                    radius: Theme.r(17)
                    // On: the colour it picked. Off: a hint of several.
                    color: Theme.accent
                    gradient: autoTile.selected ? null : autoGradient
                    Gradient {
                        id: autoGradient
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.dark ? "#71a3ff" : "#2867e4" }
                        GradientStop { position: 0.5; color: Theme.dark ? "#f075aa" : "#c32777" }
                        GradientStop { position: 1.0; color: Theme.dark ? "#cf9c00" : "#8a6700" }
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: autoTile.selected ? "check" : "image"
                        size: 17
                        stroke: autoTile.selected ? 2.6 : 2
                        color: autoTile.selected ? Theme.accentFg : "#ffffff"
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    text: "Auto"
                    size: 12
                    strong: true
                    muted: !autoTile.selected
                    wrapMode: Text.NoWrap
                }
                HoverHandler { id: autoHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: if ((Theme.conf.wallpaper || "") !== "")
                        Theme.setValue("accent_auto", !autoTile.selected)
                }
            }

            Repeater {
                model: accents
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    // With Auto on, only the Auto tile is marked (it shows the
                    // colour it picked).
                    readonly property bool selected: Theme.accentName === modelData.id && Theme.conf.accent_auto !== "true"
                    readonly property bool current: selected
                    readonly property color swatch: Theme.dark ? modelData.dark : modelData.light

                    width: 92
                    height: 88
                    radius: Theme.radiusSmall
                    color: selected ? Theme.field : tileHover.hovered ? Theme.field : "transparent"
                    border.width: current ? 2 : 1
                    border.color: current ? tile.swatch : Theme.line
                    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }

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
                  ? "A soft accent glow around the window you're using. While it's on, the window you open or switch to appears without its fade (a picom bug), so it's off by default."
                  : "An accent outline around the window you're using."
            Toggle {
                enabled: Theme.conf.compositor !== "false"
                checked: Theme.conf.window_border === "true"
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

    Card {
        title: "Other apps (experimental)"
        description: "Your colours in apps that have their own themes. Each writes a lumen theme into the app's theme folder and turns it on; switching it off removes it again. GTK, Qt and KDE apps and kitty follow the theme already."

        SettingRow {
            label: "Discord"
            description: "Through Vesktop, Vencord, Equicord or Equibop (installed and opened once). Updates live."
            Toggle {
                checked: Theme.conf.theme_discord === "true"
                onToggled: c => Theme.setValue("theme_discord", c)
            }
        }
        SettingRow {
            label: "Firefox and LibreWolf"
            description: "Toolbar, tabs, menus and the new tab page, in every profile. Restart the browser to see changes."
            Toggle {
                checked: Theme.conf.theme_browser === "true"
                onToggled: c => Theme.setValue("theme_browser", c)
            }
        }
        SettingRow {
            label: "btop"
            description: "The terminal system monitor. Reopen it to see changes."
            Toggle {
                checked: Theme.conf.theme_btop === "true"
                onToggled: c => Theme.setValue("theme_btop", c)
            }
        }
        SettingRow {
            label: "Telegram"
            description: Theme.conf.theme_telegram === "true"
                ? "Telegram only takes a theme you open in it: press Open, then Apply. Do it again after changing colours."
                : "Telegram Desktop. Turning it off later: pick another theme in Telegram's chat settings."
            RowLayout {
                spacing: 8
                Btn {
                    visible: Theme.conf.theme_telegram === "true"
                    text: "Open"
                    variant: "ghost"
                    onClicked: Quickshell.execDetached(["lumen-theme", "telegram-open"])
                }
                Toggle {
                    checked: Theme.conf.theme_telegram === "true"
                    onToggled: c => Theme.setValue("theme_telegram", c)
                }
            }
        }
        SettingRow {
            label: "Heroic Games Launcher"
            description: Theme.conf.theme_heroic === "true"
                ? "In Heroic: Settings › Accessibility › Theme › lumen (once; pick it again after changing colours). Close Heroic before turning this on, so it keeps the themes folder."
                : "A lumen theme for Heroic's own theme picker."
            Toggle {
                checked: Theme.conf.theme_heroic === "true"
                onToggled: c => Theme.setValue("theme_heroic", c)
            }
        }
        SettingRow {
            label: "fastfetch"
            description: "Accent-coloured keys and logo. Replaces your fastfetch config while on (yours comes back when it's off)."
            Toggle {
                checked: Theme.conf.theme_fastfetch === "true"
                onToggled: c => Theme.setValue("theme_fastfetch", c)
            }
        }
        SettingRow {
            label: "foot"
            description: "foot runs on Wayland only, so this is for your other sessions. New foot windows get the colours."
            Toggle {
                checked: Theme.conf.theme_foot === "true"
                onToggled: c => Theme.setValue("theme_foot", c)
            }
        }
        SettingRow {
            label: "zathura"
            description: "The keyboard-driven PDF viewer. Reopen it to see changes."
            Toggle {
                checked: Theme.conf.theme_zathura === "true"
                onToggled: c => Theme.setValue("theme_zathura", c)
            }
        }
    }
}
