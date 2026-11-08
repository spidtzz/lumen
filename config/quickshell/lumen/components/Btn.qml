import QtQuick
import QtQuick.Layouts
import qs.services

// Button with the demo's variants: normal, primary, ghost, danger.
Rectangle {
    id: btn

    property string text
    property string icon
    property string variant: "normal"
    property bool busy: false
    signal clicked()

    readonly property color fg: variant === "primary" ? Theme.accentFg
        : variant === "danger" ? "#ffffff" : Theme.ink

    implicitWidth: row.implicitWidth + (text === "" ? 18 : 26)
    implicitHeight: 38
    radius: Theme.radiusSmall
    opacity: enabled ? 1 : 0.5
    color: variant === "primary" ? Theme.accent
         : variant === "danger" ? Theme.danger
         : variant === "ghost" ? (hover.hovered ? Theme.field : "transparent")
         : Theme.field
    border.width: 1
    border.color: variant === "primary" ? Theme.accent
                : variant === "danger" ? Theme.danger
                : (hover.hovered && enabled) || btn.activeFocus ? Theme.accent : Theme.line
    scale: tap.pressed && enabled ? 0.97 : 1
    activeFocusOnTab: true

    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon {
            visible: btn.icon !== "" && !btn.busy
            name: btn.icon
            color: btn.fg
            size: 17
        }
        Txt {
            visible: btn.busy
            text: "…"
            color: btn.fg
            strong: true
        }
        Txt {
            visible: btn.text !== ""
            text: btn.text
            color: btn.fg
            strong: true
            wrapMode: Text.NoWrap
        }
    }

    HoverHandler { id: hover; cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { id: tap; enabled: btn.enabled && !btn.busy; onTapped: btn.clicked() }
    Keys.onSpacePressed: if (enabled && !busy) clicked()
    Keys.onReturnPressed: if (enabled && !busy) clicked()
}
