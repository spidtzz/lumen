import QtQuick
import qs.services

// A battery drawn to scale: the fill shows the charge, a bolt shows charging.
Item {
    id: root

    property real level: Battery.level      // 0-1
    property bool charging: Battery.charging || Battery.full
    property bool low: Battery.low
    property color color: Theme.ink
    property real size: 16                  // height of the matching line icons

    implicitWidth: Math.round(size * 1.45)
    implicitHeight: size

    // body
    Rectangle {
        id: body
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - nub.width - 1
        height: Math.round(root.size * 0.68)
        radius: Theme.r(Math.round(root.size * 0.16))
        color: "transparent"
        border.width: Math.max(1.5, root.size / 9)
        border.color: root.low ? Theme.danger : root.color

        Rectangle {
            readonly property real inset: body.border.width + 1.5
            x: inset
            y: inset
            height: parent.height - inset * 2
            width: Math.max(root.level > 0 ? 1.5 : 0, (parent.width - inset * 2) * Math.min(1, root.level))
            radius: Theme.r(1)
            color: root.low ? Theme.danger : root.color
            opacity: root.charging ? 0.35 : 1   // so the bolt shows on top
            Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
        }
    }
    // terminal
    Rectangle {
        id: nub
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(1.5, root.size / 9)
        height: Math.round(root.size * 0.3)
        radius: Theme.r(1)
        color: root.low ? Theme.danger : root.color
    }
    // charging bolt
    Icon {
        visible: root.charging
        anchors.centerIn: body
        name: "zap"
        size: root.size * 0.78
        stroke: 2.4
        color: root.color
    }
}
