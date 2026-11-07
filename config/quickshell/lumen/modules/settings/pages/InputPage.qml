import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Page {
    id: page
    title: "Keyboard & Mouse"
    description: "Layouts, key repeat and pointer settings."

    readonly property var layouts: Keyboard.layouts
    // Every layout lumen knows a name for, A–Z, for the "Add" list.
    readonly property var known: Object.keys(Keyboard.names)
        .map(k => ({ value: k, label: Keyboard.names[k] }))
        .sort((a, b) => a.label.localeCompare(b.label))
    readonly property string switchKeys: ({ alt_shift: "Alt + Shift", ctrl_shift: "Ctrl + Shift", caps: "Caps Lock" })[Theme.conf.kb_switch || "alt_shift"]

    function setLayouts(list) { Theme.setValue("kb_layouts", list.join(",")); }
    function move(i, by) {
        const l = layouts.slice();
        const j = i + by;
        if (j < 0 || j >= l.length) return;
        [l[i], l[j]] = [l[j], l[i]];
        setLayouts(l);
    }

    Card {
        title: "Keyboard layouts"
        description: page.layouts.length > 1
            ? "Switch with " + page.switchKeys + ", or click " + Keyboard.shortOf(Keyboard.current) + " in the bar. The first layout is the one you start with."
            : "Add a second layout to type in another language."

        Repeater {
            model: page.layouts
            delegate: Rectangle {
                id: row
                required property string modelData
                required property int index
                readonly property bool active: Keyboard.current === modelData

                Layout.fillWidth: true
                implicitHeight: 56
                radius: Theme.radiusSmall
                color: Theme.field
                border.width: active && page.layouts.length > 1 ? 2 : 1
                border.color: active && page.layouts.length > 1 ? Theme.accent : Theme.line

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 12

                    // Short name, as shown in the bar.
                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: 30
                        radius: Theme.r(8)
                        color: row.active ? Theme.accent : Theme.panel
                        border.width: 1
                        border.color: row.active ? Theme.accent : Theme.line
                        Txt {
                            anchors.centerIn: parent
                            text: Keyboard.shortOf(row.modelData)
                            size: 12
                            strong: true
                            color: row.active ? Theme.accentFg : Theme.ink
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Txt { text: Keyboard.nameOf(row.modelData); strong: true; Layout.fillWidth: true; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                        Txt {
                            text: [row.index === 0 ? "Default" : "", row.active && page.layouts.length > 1 ? "In use now" : ""]
                                .filter(t => t !== "").join(" · ")
                            visible: text !== ""
                            size: 12
                            muted: true
                        }
                    }
                    Btn {
                        visible: !row.active
                        text: "Use now"
                        variant: "ghost"
                        onClicked: Keyboard.set(row.modelData)
                    }
                    Btn {
                        icon: "chevron-up"
                        variant: "ghost"
                        enabled: row.index > 0
                        onClicked: page.move(row.index, -1)
                    }
                    Btn {
                        icon: "chevron-down"
                        variant: "ghost"
                        enabled: row.index < page.layouts.length - 1
                        onClicked: page.move(row.index, 1)
                    }
                    Btn {
                        icon: "trash"
                        variant: "ghost"
                        enabled: page.layouts.length > 1
                        onClicked: page.setLayouts(page.layouts.filter(l => l !== row.modelData))
                    }
                }
            }
        }

        SettingRow {
            label: "Add a layout"
            description: page.layouts.length < 4 ? "" : "Four is the most X11 allows. Remove one to add another."
            Dropdown {
                enabled: page.layouts.length < 4
                searchable: true
                placeholder: "Choose a language…"
                options: page.known.filter(k => !page.layouts.includes(k.value))
                value: ""
                onPicked: v => page.setLayouts(page.layouts.concat([v]))
            }
        }
    }

    Card {
        title: "Switching layouts"
        description: "Press and release the keys together, without another key. Left or right keys both work, and AltGr shortcuts aren't affected."
        opacity: page.layouts.length > 1 ? 1 : 0.5
        enabled: page.layouts.length > 1

        SettingRow {
            label: "Switch with"
            Seg {
                options: [
                    { label: "Alt + Shift", value: "alt_shift" },
                    { label: "Ctrl + Shift", value: "ctrl_shift" },
                    { label: "Caps Lock", value: "caps" }
                ]
                value: Theme.conf.kb_switch || "alt_shift"
                onPicked: v => Theme.setValue("kb_switch", v)
            }
        }

        Field {
            Layout.fillWidth: true
            placeholderText: "Try it here: type, switch, type again"
        }
    }

    Card {
        title: "Key repeat"
        description: "How a held key repeats."

        SettingRow {
            label: "Delay"
            description: "Before repeating starts."
            LSlider {
                id: delay
                from: 150; to: 1000; stepSize: 50
                value: +(Theme.conf.repeat_delay || 400)
                onCommitted: v => Theme.setValue("repeat_delay", Math.round(v))
            }
            Txt { text: Math.round(delay.value) + " ms"; muted: true; Layout.preferredWidth: 64 }
        }
        SettingRow {
            label: "Speed"
            description: "Repeats per second."
            LSlider {
                id: rate
                from: 10; to: 60; stepSize: 1
                value: +(Theme.conf.repeat_rate || 30)
                onCommitted: v => Theme.setValue("repeat_rate", Math.round(v))
            }
            Txt { text: Math.round(rate.value) + " /s"; muted: true; Layout.preferredWidth: 64 }
        }
    }

    Card {
        title: "Mouse & touchpad"

        SettingRow {
            label: "Focus follows mouse"
            description: "Windows get keyboard focus when the pointer moves onto them, without clicking."
            Toggle {
                checked: Theme.conf.focus_follows_mouse !== "false"
                onToggled: c => Theme.setValue("focus_follows_mouse", c)
            }
        }

        SettingRow {
            label: "Pointer speed"
            LSlider {
                id: speed
                from: -1; to: 1; stepSize: 0.05
                value: +(Theme.conf.pointer_speed || 0)
                onCommitted: v => Theme.setValue("pointer_speed", v.toFixed(2))
            }
            Txt {
                text: speed.value === 0 ? "Default" : (speed.value > 0 ? "+" : "") + Math.round(speed.value * 100) + "%"
                muted: true
                Layout.preferredWidth: 64
            }
        }
        SettingRow {
            label: "Natural scrolling"
            description: "Content moves with your fingers, like on a phone."
            Toggle {
                checked: Theme.conf.natural_scroll === "true"
                onToggled: c => Theme.setValue("natural_scroll", c)
            }
        }
        SettingRow {
            label: "Tap to click"
            description: "Touchpads only."
            Toggle {
                checked: Theme.conf.tap_to_click !== "false"
                onToggled: c => Theme.setValue("tap_to_click", c)
            }
        }
    }
}
