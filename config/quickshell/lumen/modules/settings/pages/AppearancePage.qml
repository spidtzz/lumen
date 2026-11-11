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

    // A small desktop in the current look: mode, accent, corners.
    Card {
        Rectangle {
            id: mock
            Layout.fillWidth: true
            Layout.preferredHeight: 190
            radius: Theme.radiusSmall
            color: Theme.bg
            border.width: 1
            border.color: Theme.line
            clip: true
            readonly property real rr: Theme.rounded ? 10 : 0

            // wallpaper hint
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) }
                    GradientStop { position: 1; color: Theme.bg }
                }
            }
            // bar
            Rectangle {
                x: 10; y: 10
                width: parent.width - 20; height: 22
                radius: Theme.rounded ? 8 : 0
                color: Theme.barBg
                border.width: 1
                border.color: Theme.line
                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Rectangle { width: 18; height: 6; radius: 3; color: Theme.accent }
                    Repeater { model: 3; Rectangle { width: 6; height: 6; radius: 3; color: Theme.line } }
                }
                Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 40; height: 6; radius: 3; color: Theme.muted; opacity: 0.6 }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; width: 30; height: 12; radius: Theme.rounded ? 6 : 0; color: Theme.accent }
            }
            // a window
            Rectangle {
                x: 24; y: 46
                width: parent.width * 0.55; height: parent.height - 62
                radius: mock.rr
                color: Theme.panel
                border.width: 1
                border.color: Theme.line
                Column {
                    x: 14; y: 14
                    spacing: 8
                    Rectangle { width: 120; height: 8; radius: 4; color: Theme.ink; opacity: 0.85 }
                    Rectangle { width: 170; height: 6; radius: 3; color: Theme.muted; opacity: 0.6 }
                    Rectangle { width: 150; height: 6; radius: 3; color: Theme.muted; opacity: 0.6 }
                    Row {
                        spacing: 8
                        topPadding: 6
                        Rectangle { width: 64; height: 22; radius: Theme.rounded ? 7 : 0; color: Theme.accent
                            Rectangle { anchors.centerIn: parent; width: 36; height: 5; radius: 2.5; color: Theme.accentFg } }
                        Rectangle { width: 64; height: 22; radius: Theme.rounded ? 7 : 0; color: Theme.field; border.width: 1; border.color: Theme.line
                            Rectangle { anchors.centerIn: parent; width: 36; height: 5; radius: 2.5; color: Theme.ink; opacity: 0.7 } }
                    }
                }
            }
            // a second window, smaller
            Rectangle {
                x: parent.width * 0.55 + 36; y: 46
                width: parent.width - x - 24; height: parent.height - 62
                radius: mock.rr
                color: Theme.panel
                border.width: 1
                border.color: Theme.line
                Column {
                    x: 12; y: 14
                    spacing: 8
                    Repeater {
                        model: 4
                        Row {
                            spacing: 8
                            Rectangle { width: 14; height: 14; radius: Theme.rounded ? 7 : 0; color: index === 0 ? Theme.accent : Theme.field; border.width: 1; border.color: Theme.line }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 70 - index * 8; height: 6; radius: 3; color: Theme.muted; opacity: 0.6 }
                        }
                    }
                }
            }
        }
    }

    Card {
        title: "Style"
        SettingRow {
            label: "Mode"
            icon: "palette"
            description: "For the shell and every app. Black is dark on pure black (for OLED screens)."
            Seg {
                options: [{ label: "Light", value: "light" }, { label: "Dark", value: "dark" }, { label: "Black", value: "black" }]
                value: Theme.mode
                onPicked: v => Theme.setValue("mode", v)
            }
        }
        SettingRow {
            label: "Corners"
            icon: "corner"
            description: "Rounded or square, for the shell, windows, GTK apps and the login screen. Qt apps keep their own small corners."
            Seg {
                options: [{ label: "Rounded", value: "rounded" }, { label: "Square", value: "square" }]
                value: Theme.rounded ? "rounded" : "square"
                onPicked: v => Theme.setValue("corners", v)
            }
        }
        SettingRow {
            label: "Rounded screen corners"
            icon: "monitor"
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
            icon: "type"
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
            icon: "window"
            description: Theme.conf.compositor === "false"
                ? "An accent outline. Always on while the compositor is off (Settings › Power)."
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
            icon: "x"
            description: "Minimise, maximise and close buttons in apps that draw their own title bar. Off by default: close windows with super + Q. Open apps update after a restart."
            Toggle {
                checked: Theme.conf.window_buttons === "true"
                onToggled: c => Theme.setValue("window_buttons", c)
            }
        }
    }

    // An app with its own theme: a tile with a switch.
    component AppTile: Rectangle {
        id: tile
        property string name
        property string hint      // one line, shown under the name
        property string key       // settings key
        property string note: ""  // shown while it's on (what to do in the app)
        property bool defaultOn: false
        readonly property bool active: Theme.conf[key] === "true" || (Theme.conf[key] === undefined && defaultOn)
        default property alias extra: extraRow.data

        Layout.fillWidth: true
        Layout.fillHeight: true   // tiles in a row share its height
        Layout.preferredWidth: 1
        implicitHeight: tileCol.implicitHeight + 24
        radius: Theme.radiusSmall
        color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08) : Theme.field
        border.width: 1
        border.color: active ? Theme.accent : Theme.line
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        ColumnLayout {
            id: tileCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Txt { text: tile.name; strong: true; Layout.fillWidth: true; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                Toggle { checked: tile.active; onToggled: c => Theme.setValue(tile.key, c) }
            }
            Txt { text: tile.active && tile.note !== "" ? tile.note : tile.hint; muted: true; size: 12; Layout.fillWidth: true }
            RowLayout { id: extraRow; visible: tile.active && children.length > 0; spacing: 8 }
        }
    }

    Card {
        title: "Other apps"
        description: "Your colours in apps with their own themes (experimental). Turning one off puts the app's own look back. GTK, Qt and KDE apps and kitty always follow the theme."

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            AppTile { name: "Firefox and LibreWolf"; key: "theme_browser"; hint: "Toolbar, tabs, menus and the new tab page."; note: "Restart the browser to see changes." }
            AppTile { name: "Discord"; key: "theme_discord"; hint: "Vesktop, Vencord, Equicord or Equibop."; note: "Updates live." }
            AppTile {
                name: "Telegram"; key: "theme_telegram"; hint: "Telegram Desktop."
                note: "Press Open, then Apply in Telegram. Again after changing colours."
                Btn { text: "Open in Telegram"; variant: "ghost"; onClicked: Quickshell.execDetached(["lumen-theme", "telegram-open"]) }
            }
            AppTile { name: "Heroic Games Launcher"; key: "theme_heroic"; hint: "A theme in Heroic's theme picker."; note: "In Heroic: Settings › Accessibility › Theme › lumen. Pick it again after changing colours." }
            AppTile { name: "fastfetch"; key: "theme_fastfetch"; defaultOn: true; hint: "A small lumen logo and the basics, in your colours."; note: "Your own config comes back when this is off." }
            AppTile { name: "fish"; key: "theme_fish"; defaultOn: true; hint: "lumen's prompt, colours and completions (kitty opens fish)."; note: "New terminal windows get it." }
            AppTile { name: "btop"; key: "theme_btop"; hint: "The terminal system monitor."; note: "Reopen btop to see changes." }
            AppTile { name: "zathura"; key: "theme_zathura"; hint: "The keyboard-driven PDF viewer."; note: "Reopen zathura to see changes." }
        }
    }
}
