import QtQuick
import Quickshell
import qs.services

// Holds the bar's popups (calendar, quick settings, tray). It covers the
// screen while a popup is open so a click anywhere else closes it.
PanelWindow {
    id: layer

    required property var modelData
    screen: modelData

    visible: Panels.popup !== "" && Panels.popupScreen === modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property string edge: Theme.barPosition

    // Place a w×h popup next to the button that opened it, inside the screen.
    function place(w, h) {
        const a = Panels.popupAnchor;
        const g = Theme.gap;
        const off = Theme.barThickness + 8;
        const hasAnchor = a.width > 0;
        let x, y;
        if (edge === "top" || edge === "bottom") {
            x = hasAnchor ? a.x + a.width / 2 - w / 2 : width - w - g;
            y = edge === "top" ? off : height - off - h;
        } else {
            y = hasAnchor ? a.y : g;
            x = edge === "left" ? off : width - off - w;
        }
        return Qt.point(Math.max(g, Math.min(x, width - w - g)), Math.max(g, Math.min(y, height - h - g)));
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: Panels.closePopup()
    }

    Loader {
        id: content
        readonly property point pos: item ? layer.place(item.implicitWidth, item.implicitHeight) : Qt.point(0, 0)
        x: pos.x
        y: pos.y
        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0
        active: layer.visible
        source: Panels.popup === "calendar" ? "CalendarPopup.qml"
              : Panels.popup === "qs" ? "QuickSettings.qml"
              : Panels.popup === "tray" ? "TrayPopup.qml" : ""

        // Fade and slide in from the bar.
        opacity: status === Loader.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
        transform: Translate {
            y: content.status === Loader.Ready ? 0 : (layer.edge === "bottom" ? 8 : layer.edge === "top" ? -8 : 0)
            x: content.status === Loader.Ready ? 0 : (layer.edge === "right" ? 8 : layer.edge === "left" ? -8 : 0)
            Behavior on x { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
        }
    }
}
