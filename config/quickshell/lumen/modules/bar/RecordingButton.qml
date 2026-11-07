import QtQuick
import qs.services

// Red dot and time while recording. Click to stop.
BarButton {
    id: btn

    visible: Recorder.recording
    padding: 9
    onClicked: Recorder.stop()

    Row {
        spacing: 7
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 9; height: 9; radius: Theme.r(5)
            color: Theme.danger
            SequentialAnimation on opacity {
                running: Recorder.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
        TextMetrics { id: widest; font: elapsed.font; text: "88:88" }
        Text {
            id: elapsed
            visible: !btn.vertical
            width: widest.advanceWidth + 2
            text: Math.floor(Recorder.elapsed / 60) + ":" + String(Recorder.elapsed % 60).padStart(2, "0")
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(12 * Theme.fontScale)
            font.weight: Font.Bold
            font.features: ({ "tnum": 1 })
            color: Theme.ink
        }
    }
}
