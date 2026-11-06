import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Page {
    id: page
    title: "Keyboard & Mouse"
    description: "Layouts, key repeat and pointer settings."

    readonly property var known: [
        { value: "us", label: "English (US)" }, { value: "gb", label: "English (UK)" },
        { value: "ir", label: "Persian" }, { value: "ara", label: "Arabic" },
        { value: "tr", label: "Turkish" }, { value: "de", label: "German" },
        { value: "fr", label: "French" }, { value: "es", label: "Spanish" },
        { value: "it", label: "Italian" }, { value: "pt", label: "Portuguese" },
        { value: "br", label: "Portuguese (Brazil)" }, { value: "ru", label: "Russian" },
        { value: "ua", label: "Ukrainian" }, { value: "pl", label: "Polish" },
        { value: "nl", label: "Dutch" }, { value: "se", label: "Swedish" },
        { value: "no", label: "Norwegian" }, { value: "dk", label: "Danish" },
        { value: "fi", label: "Finnish" }, { value: "gr", label: "Greek" },
        { value: "il", label: "Hebrew" }, { value: "in", label: "Hindi" },
        { value: "jp", label: "Japanese" }, { value: "kr", label: "Korean" }
    ]
    readonly property var layouts: (Theme.conf.kb_layouts || "us").split(",")

    function labelFor(code) {
        const k = known.find(x => x.value === code);
        return k ? k.label : code;
    }
    function setLayouts(list) { Theme.setValue("kb_layouts", list.join(",")); }

    Card {
        title: "Keyboard layouts"
        description: "The first layout is the default. Up to four."

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: page.layouts
                delegate: Chip {
                    required property string modelData
                    required property int index
                    text: page.labelFor(modelData)
                    checked: index === 0
                    removable: page.layouts.length > 1
                    // Clicking a layout makes it the default.
                    onClicked: if (index > 0) page.setLayouts([modelData].concat(page.layouts.filter(l => l !== modelData)))
                    onRemoved: page.setLayouts(page.layouts.filter(l => l !== modelData))
                }
            }
        }

        SettingRow {
            label: "Add a layout"
            visible: page.layouts.length < 4
            Dropdown {
                searchable: true
                placeholder: "Choose a language…"
                options: page.known.filter(k => !page.layouts.includes(k.value))
                value: ""
                onPicked: v => page.setLayouts(page.layouts.concat([v]))
            }
        }

        SettingRow {
            visible: page.layouts.length > 1
            label: "Switch layouts with"
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
            placeholderText: "Type here to test"
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
