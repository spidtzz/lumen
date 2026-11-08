import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services
import qs.components

// One lock screen per monitor, in the same design as the SDDM login screen.
// A normal window (so bspwm gives it keyboard focus); lumen-lock adds a rule
// for each "lumen Lock <monitor>" title: fullscreen, on top, on that monitor.
FloatingWindow {
    id: surface

    required property var modelData
    required property var lock
    screen: modelData

    title: "lumen Lock " + modelData.name
    implicitWidth: modelData.width
    implicitHeight: modelData.height
    color: Theme.bg

    // Wallpaper from Settings, dimmed, behind everything.
    Image {
        anchors.fill: parent
        visible: (Theme.conf.wallpaper || "") !== "" && status === Image.Ready
        source: Theme.conf.wallpaper ? "file://" + Theme.conf.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(surface.modelData.width, surface.modelData.height)
        Rectangle { anchors.fill: parent; color: Theme.bg; opacity: 0.55 }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Connections {
        target: surface.lock
        function onFailed() {
            shake.restart();
        }
    }

    // ---- soft accent glows ----
    Item {
        id: glow
        anchors.fill: parent
        visible: false
        Rectangle {
            width: surface.width * 0.55; height: width; radius: width / 2
            x: -width * 0.25; y: -height * 0.3
            color: Theme.accent
            opacity: Theme.dark ? 0.22 : 0.16
        }
        Rectangle {
            width: surface.width * 0.45; height: width; radius: width / 2
            x: surface.width - width * 0.7; y: surface.height - height * 0.6
            color: Theme.accent
            opacity: Theme.dark ? 0.14 : 0.10
        }
    }
    MultiEffect {
        anchors.fill: glow
        visible: (Theme.conf.wallpaper || "") === ""
        source: glow
        blurEnabled: true
        blurMax: 64
        blur: 1.0
    }

    // ---- clock ----
    Column {
        NumberAnimation on opacity { from: 0; to: 1; duration: Theme.animSlow * 1.4; easing.type: Theme.easeOut }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 40
        spacing: 2
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, Theme.clock24h ? "HH:mm" : "h:mm")
            size: 88
            strong: true
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.date.toLocaleDateString(Qt.locale(), Locale.LongFormat)
            size: 18
            muted: true
        }
    }

    // ---- card ----
    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60 + rise
        property real rise: 0
        NumberAnimation on rise { from: 24; to: 0; duration: Theme.animSlow; easing.type: Theme.easeOut }
        NumberAnimation on opacity { from: 0; to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }
        width: 380
        height: cardCol.implicitHeight + 48
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.line
        border.width: 1

        transform: Translate { id: shakeX }
        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: shakeX; property: "x"; to: -10; duration: 50; easing.type: Easing.OutSine }
            NumberAnimation { target: shakeX; property: "x"; to: 10; duration: 80; easing.type: Easing.InOutSine }
            NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 50; easing.type: Easing.InSine }
        }

        Column {
            id: cardCol
            anchors.top: parent.top
            anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 48
            spacing: 14

            Item {
                width: 96; height: 96
                anchors.horizontalCenter: parent.horizontalCenter
                Avatar { anchors.fill: parent; size: 96 }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: Theme.r(width / 2)
                    color: "transparent"
                    border.color: Theme.line
                    border.width: 2
                }
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Theme.userName
                size: 22
                strong: true
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: parent.width - submit.width - parent.spacing
                    height: 44
                    radius: Theme.radiusSmall
                    color: Theme.field
                    border.width: 2
                    border.color: surface.lock.error !== "" ? Theme.danger : Theme.accent

                    Icon {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.verticalCenter: parent.verticalCenter
                        name: "lock"
                        size: 17
                        color: surface.lock.error !== "" ? Theme.danger : Theme.muted
                    }
                    // Dots for what's typed (keys come from lumen-lock-grab).
                    Text {
                        id: password
                        readonly property int count: Array.from(surface.lock.typed).length
                        anchors.left: lockIcon.right
                        anchors.right: layout.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        text: "•".repeat(count)
                        color: Theme.ink
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        elide: Text.ElideLeft
                    }
                    Txt {
                        anchors.left: lockIcon.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: surface.lock.inputReady ? "Password" : "Starting…"
                        size: 16
                        muted: true
                        visible: password.count === 0
                    }
                    // Keyboard layout, when there's more than one.
                    Row {
                        id: layout
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Keyboard.layouts.length > 1
                        width: visible ? implicitWidth : 0
                        spacing: 5
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "keyboard"; size: 15; color: Theme.muted }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Keyboard.shortOf(Keyboard.current)
                            size: 12
                            strong: true
                            muted: true
                        }
                    }
                }

                Rectangle {
                    id: submit
                    width: 44; height: 44
                    radius: Theme.radiusSmall
                    color: Theme.accent
                    Txt {
                        anchors.centerIn: parent
                        visible: surface.lock.busy
                        text: "…"
                        size: 22
                        strong: true
                        color: Theme.accentFg
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: !surface.lock.busy
                        name: "arrow-right"
                        size: 20
                        stroke: 2.4
                        color: Theme.accentFg
                    }
                    // (Enter submits; the mouse is held by the lock while locked.)
                }
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                size: 13
                text: surface.lock.error !== "" ? surface.lock.error
                    : surface.lock.busy ? "Checking…" : "Locked. Type your password and press Enter."
                color: surface.lock.error !== "" ? Theme.danger : Theme.muted
            }
        }
    }

    Txt {
        visible: surface.lock.testMode
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 24
        text: "Test mode: press Esc to close"
        size: 13
        muted: true
    }

}
