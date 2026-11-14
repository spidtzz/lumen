import QtQuick
import QtQuick.Controls.Basic
import qs.services
import qs.components

// One key, drawn like a keyboard key. Modifiers and special keys get an icon
// (with their name on hover); letters, digits and the rest stay text.
Rectangle {
    id: cap

    property string key          // as Sxhkd.js prints it: "Super", "Enter", "Q", "Volume +"

    // icon, text beside it (or alone), and the name for the hover hint
    readonly property var look: {
        const k = key;
        const icons = {
            "Super": ["key-super", "", "Super"],
            "Shift": ["key-shift", "", "Shift"],
            "Ctrl": ["key-ctrl", "", "Ctrl"],
            "Alt": ["key-alt", "", "Alt"],
            "AltGr": ["key-alt", "Gr", "AltGr"],
            "Enter": ["key-enter", "", "Enter"],
            "Tab": ["key-tab", "", "Tab"],
            "Esc": ["key-esc", "", "Esc"],
            "Space": ["key-space", "", "Space"],
            "Backspace": ["key-backspace", "", "Backspace"],
            "Delete": ["key-delete", "", "Delete"],
            "Print": ["camera", "", "Print Screen"],
            "←": ["arrow-left", "", "Left"],
            "→": ["arrow-right", "", "Right"],
            "↑": ["arrow-up", "", "Up"],
            "↓": ["arrow-down", "", "Down"],
            "Volume +": ["volume", "+", "Volume up"],
            "Volume −": ["volume", "−", "Volume down"],
            "Mute": ["volume-x", "", "Mute"],
            "Mic mute": ["mic-off", "", "Microphone mute"],
            "Brightness +": ["brightness", "+", "Brightness up"],
            "Brightness −": ["brightness", "−", "Brightness down"],
            "Play": ["play", "", "Play / pause"],
            "Pause": ["pause", "", "Pause"],
            "Stop": ["key-stop", "", "Stop"],
            "Next track": ["skip-forward", "", "Next track"],
            "Previous track": ["skip-back", "", "Previous track"],
            "Left click": ["mouse", "L", "Left click"],
            "Middle click": ["mouse", "M", "Middle click"],
            "Right click": ["mouse", "R", "Right click"],
            "Scroll up": ["mouse", "↑", "Scroll up"],
            "Scroll down": ["mouse", "↓", "Scroll down"],
            "Touchpad Toggle": ["key-touchpad", "", "Touchpad key"]
        };
        const v = icons[k];
        return v ? { icon: v[0], text: v[1], name: v[2] } : { icon: "", text: k, name: "" };
    }

    implicitWidth: Math.max(28, inner.implicitWidth + (look.icon !== "" && look.text === "" ? 14 : 16))
    implicitHeight: 28
    radius: Theme.r(6)
    color: Theme.bg
    border.width: 1
    border.color: Theme.line

    // a deeper bottom edge, like a key
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: parent.radius / 2
        anchors.rightMargin: parent.radius / 2
        height: 2
        color: Theme.line
    }

    Row {
        id: inner
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        spacing: 3
        Icon {
            visible: cap.look.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: cap.look.icon
            size: 14
            stroke: 2.2
        }
        Txt {
            visible: cap.look.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: cap.look.text
            size: 12
            strong: true
            wrapMode: Text.NoWrap
            font.features: ({ "tnum": 1 })
        }
    }

    HoverHandler { id: hover }
    ToolTip.visible: hover.hovered && look.name !== ""
    ToolTip.delay: 300
    ToolTip.text: look.name
}
