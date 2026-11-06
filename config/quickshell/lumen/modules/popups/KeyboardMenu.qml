import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// List of keyboard layouts in use (right click on the bar's layout button).
PopupCard {
    id: menu

    padding: 6
    spacing: 2
    implicitWidth: 230

    Repeater {
        model: Keyboard.layouts
        delegate: MenuRow {
            required property string modelData
            text: Keyboard.nameOf(modelData) + "  ·  " + Keyboard.shortOf(modelData)
            checked: modelData === Keyboard.current
            onClicked: {
                Keyboard.set(modelData);
                Panels.closePopup();
            }
        }
    }

    Rectangle { Layout.fillWidth: true; Layout.topMargin: 3; Layout.bottomMargin: 3; implicitHeight: 1; color: Theme.line }

    MenuRow {
        icon: "keyboard"
        text: "Keyboard settings"
        onClicked: Panels.openSettings("input")
    }
}
