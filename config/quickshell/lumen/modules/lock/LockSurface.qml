import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services
import qs.components
import "../../components/Jalali.js" as Jalali

// One lock screen per monitor, in the same design as the SDDM login screen.
PanelWindow {
    id: surface

    required property var modelData
    required property var lock
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    color: Theme.bg

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Connections {
        target: surface.lock
        function onFailed() {
            password.text = "";
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
        source: glow
        blurEnabled: true
        blurMax: 64
        blur: 1.0
    }

    // ---- clock ----
    Column {
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
            text: Theme.shamsiDate ? Jalali.format(clock.date, true) : Qt.formatDateTime(clock.date, "dddd, d MMMM")
            size: 18
            muted: true
        }
    }

    // ---- card ----
    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
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
            NumberAnimation { target: shakeX; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: shakeX; property: "x"; to: 10; duration: 80 }
            NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 50 }
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
                    radius: width / 2
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
                    border.width: password.activeFocus ? 2 : 1
                    border.color: surface.lock.error !== "" ? Theme.danger
                        : password.activeFocus ? Theme.accent : Theme.line

                    TextInput {
                        id: password
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.ink
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentFg
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        clip: true
                        focus: true
                        enabled: !surface.lock.busy
                        onTextEdited: surface.lock.error = ""
                        Keys.onReturnPressed: surface.lock.submit(text)
                        Keys.onEnterPressed: surface.lock.submit(text)
                        Keys.onEscapePressed: {
                            if (surface.lock.testMode) Qt.quit();
                            else text = "";
                        }
                    }
                    Txt {
                        anchors.fill: password
                        verticalAlignment: Text.AlignVCenter
                        text: "Password"
                        size: 16
                        muted: true
                        visible: password.text.length === 0
                    }
                }

                Rectangle {
                    id: submit
                    width: 44; height: 44
                    radius: Theme.radiusSmall
                    color: Theme.accent
                    Txt {
                        anchors.centerIn: parent
                        text: surface.lock.busy ? "…" : "→"
                        size: 22
                        strong: true
                        color: Theme.accentFg
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: surface.lock.submit(password.text) }
                }
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                size: 13
                text: surface.lock.error !== "" ? surface.lock.error
                    : surface.lock.busy ? "Checking…" : "Locked. Enter your password to unlock."
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

    // Clicking anywhere puts the cursor back in the password field.
    TapHandler { onTapped: password.forceActiveFocus() }
    Component.onCompleted: password.forceActiveFocus()
}
