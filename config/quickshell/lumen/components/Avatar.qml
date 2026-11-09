import QtQuick
import QtQuick.Effects
import Quickshell.Io
import qs.services

// Round profile picture from ~/.face, or the user's initial in an accent
// circle when there's no picture. Shared by the bar and (later) Settings.
Item {
    id: root

    property int size: 26
    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
        layer.enabled: true

        // Only when there's a picture (no warning for a missing ~/.face).
        function refresh() {
            source = "";
            faceCheck.running = false;
            faceCheck.running = true;
        }
        Process {
            id: faceCheck
            command: ["test", "-s", Theme.avatarPath]
            onExited: code => img.source = code === 0 ? "file://" + Theme.avatarPath : ""
        }
        Component.onCompleted: refresh()
        Connections {
            target: Theme
            function onAvatarRevisionChanged() { img.refresh(); }
        }
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: Theme.r(width / 2)
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        visible: img.status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.r(width / 2)
        color: Theme.accent
        visible: img.status !== Image.Ready
        Text {
            anchors.centerIn: parent
            text: Theme.userName.length > 0 ? Theme.userName.charAt(0).toUpperCase() : "?"
            color: Theme.accentFg
            font.family: Theme.fontFamily
            font.pixelSize: root.size * 0.48
            font.weight: Font.Bold
        }
    }
}
