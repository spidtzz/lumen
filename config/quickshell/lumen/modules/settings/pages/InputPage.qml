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
    readonly property string customKeys: Theme.conf.kb_switch_custom || ""
    function prettyChord(c) {
        return c.split("+").map(p => p.trim()).map(p => p === "super" ? "Super" : p === "ctrl" ? "Ctrl" : p === "alt" ? "Alt"
            : p === "shift" ? "Shift" : p === "space" ? "Space" : p.length === 1 ? p.toUpperCase() : p).join(" + ");
    }
    readonly property string switchKeys: ({ alt_shift: "Alt + Shift", ctrl_shift: "Ctrl + Shift", caps: "Caps Lock",
        super_space: "Super + Space", custom: customKeys !== "" ? prettyChord(customKeys) : "your shortcut" })[Theme.conf.kb_switch || "alt_shift"]
    property bool recording: false
    onRecordingChanged: if (recording) catcher.forceActiveFocus()

    // A key press as sxhkd writes it: "super + shift + k". "" for keys that
    // can't be a shortcut on their own.
    function chordOf(event) {
        const k = event.key;
        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr].includes(k)) return "";
        const names = { [Qt.Key_Space]: "space", [Qt.Key_Period]: "period", [Qt.Key_Comma]: "comma", [Qt.Key_Slash]: "slash",
            [Qt.Key_Semicolon]: "semicolon", [Qt.Key_Minus]: "minus", [Qt.Key_Equal]: "equal", [Qt.Key_QuoteLeft]: "grave",
            [Qt.Key_Apostrophe]: "apostrophe", [Qt.Key_BracketLeft]: "bracketleft", [Qt.Key_BracketRight]: "bracketright",
            [Qt.Key_Backslash]: "backslash", [Qt.Key_Tab]: "Tab", [Qt.Key_Return]: "Return", [Qt.Key_Backspace]: "BackSpace" };
        let key = names[k] ?? "";
        if (!key && k >= Qt.Key_A && k <= Qt.Key_Z) key = String.fromCharCode(k).toLowerCase();
        if (!key && k >= Qt.Key_0 && k <= Qt.Key_9) key = String.fromCharCode(k);
        if (!key && k >= Qt.Key_F1 && k <= Qt.Key_F12) key = "F" + (k - Qt.Key_F1 + 1);
        if (!key) return "";
        const m = event.modifiers, parts = [];
        if (m & Qt.MetaModifier) parts.push("super");
        if (m & Qt.ControlModifier) parts.push("ctrl");
        if (m & Qt.AltModifier) parts.push("alt");
        if (m & Qt.ShiftModifier) parts.push("shift");
        if (parts.length === 0 && !key.startsWith("F")) return "";   // needs a modifier
        return parts.concat([key]).join(" + ");
    }

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
            icon: "plus"
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
        description: "Alt + Shift, Ctrl + Shift and Caps Lock work on their own (left or right keys, AltGr shortcuts aren't affected), or pick a shortcut."
        opacity: page.layouts.length > 1 ? 1 : 0.5
        enabled: page.layouts.length > 1

        SettingRow {
            icon: "keyboard"
            label: "Switch with"
            description: (Theme.conf.kb_switch || "alt_shift") === "super_space" || Theme.conf.kb_switch === "custom"
                ? "A shortcut: each press goes to the next layout." : "Press and release together, without another key."
            Dropdown {
                implicitWidth: 220
                options: [
                    { label: "Alt + Shift", value: "alt_shift" },
                    { label: "Ctrl + Shift", value: "ctrl_shift" },
                    { label: "Caps Lock", value: "caps" },
                    { label: "Super + Space", value: "super_space" },
                    { label: "Your own shortcut", value: "custom" }
                ]
                value: Theme.conf.kb_switch || "alt_shift"
                onPicked: v => { Theme.setValue("kb_switch", v); if (v === "custom" && page.customKeys === "") page.recording = true; }
            }
        }

        SettingRow {
            visible: Theme.conf.kb_switch === "custom"
            icon: "keyboard"
            label: "Your shortcut"
            description: page.recording ? "Press the keys now (with Super, Ctrl or Alt). Esc cancels."
                : "Shortcuts lumen already uses can't be picked."
            Btn {
                id: recorder
                text: page.recording ? "Press keys…" : page.customKeys !== "" ? page.prettyChord(page.customKeys) : "Set shortcut"
                variant: page.recording ? "primary" : "normal"
                onClicked: { page.recording = !page.recording; if (page.recording) catcher.forceActiveFocus(); }
            }
            Item {
                id: catcher
                width: 1; height: 1
                focus: page.recording
                onActiveFocusChanged: if (!activeFocus) page.recording = false
                Keys.onPressed: event => {
                    if (!page.recording) return;
                    event.accepted = true;
                    if (event.key === Qt.Key_Escape) { page.recording = false; return; }
                    const c = page.chordOf(event);
                    if (c === "") return;
                    Theme.setValue("kb_switch_custom", c);
                    page.recording = false;
                }
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
            icon: "clock"
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
            icon: "repeat"
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
            icon: "pointer"
      label: "Focus follows mouse"
            description: "Windows get keyboard focus when the pointer moves onto them, without clicking."
            Toggle {
                checked: Theme.conf.focus_follows_mouse !== "false"
                onToggled: c => Theme.setValue("focus_follows_mouse", c)
            }
        }

        SettingRow {
            icon: "mouse"
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
            icon: "mouse"
      label: "Natural scrolling"
            description: "Content moves with your fingers, like on a phone."
            Toggle {
                checked: Theme.conf.natural_scroll === "true"
                onToggled: c => Theme.setValue("natural_scroll", c)
            }
        }
        SettingRow {
            icon: "pointer"
      label: "Tap to click"
            description: "Touchpads only."
            Toggle {
                checked: Theme.conf.tap_to_click !== "false"
                onToggled: c => Theme.setValue("tap_to_click", c)
            }
        }
    }
}
