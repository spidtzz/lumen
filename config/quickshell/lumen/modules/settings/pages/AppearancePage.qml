import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Page {
    title: "Appearance"
    description: "Colours, text and effects. Changes apply to the shell, apps and the login screen."

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
    }

    Card {
        title: "Accent colour"
        description: "Used for selections, focused windows and highlights."
        Flow {
            Layout.fillWidth: true
            spacing: 18
            Repeater {
                model: accents
                delegate: ColumnLayout {
                    required property var modelData
                    spacing: 8
                    Swatch {
                        Layout.alignment: Qt.AlignHCenter
                        swatch: Theme.dark ? modelData.dark : modelData.light
                        selected: Theme.accentName === modelData.id
                        onClicked: Theme.setValue("accent", modelData.id)
                    }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.label
                        size: 12
                        muted: Theme.accentName !== modelData.id
                        strong: Theme.accentName === modelData.id
                    }
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
        title: "Effects"
        SettingRow {
            label: "Compositor"
            description: "Rounded corners, shadows and fades (picom). Turn off for the lightest setup."
            Toggle {
                checked: Theme.conf.compositor !== "false"
                onToggled: c => Theme.setValue("compositor", c)
            }
        }
    }
}
