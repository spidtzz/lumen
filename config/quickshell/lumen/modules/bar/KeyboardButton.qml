import QtQuick
import qs.services

// Active keyboard layout (EN, FA, ...). Click: next layout.
// Right click: list of layouts. Hidden with a single layout.
BarButton {
    id: btn

    property var bar

    visible: Keyboard.layouts.length > 1
    padding: 8
    open: Panels.popup === "keyboard" && Panels.popupScreen === bar.screen
    onClicked: Keyboard.next()
    onRightClicked: Panels.togglePopup("keyboard", bar.screen, bar.anchorOf(btn))

    Text {
        text: Keyboard.shortOf(Keyboard.current)
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(12 * Theme.fontScale)
        font.weight: Font.Bold
        color: btn.open ? Theme.accentFg : Theme.ink
    }
}
