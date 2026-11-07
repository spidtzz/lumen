import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.services
import qs.components

Page {
    id: page
    title: "Sound"
    description: "Output and input devices and their volume."

    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function nodeLabel(n) { return n.description || n.nickname || n.name; }

    // Volume and mute state are only live for tracked nodes.
    PwObjectTracker { objects: page.sinks.concat(page.sources) }

    Card {
        visible: !Pipewire.ready
        title: "PipeWire isn't running"
        description: "Sound settings need PipeWire. Install pipewire-pulse and wireplumber, then log in again."
    }

    component DeviceCard: Card {
        id: dc
        property var devices: []
        property var current: null
        property string kind: "output"
        signal choose(var node)

        visible: Pipewire.ready
        title: kind === "output" ? "Output" : "Input"

        SettingRow {
            label: dc.kind === "output" ? "Speakers or headphones" : "Microphone"
            Dropdown {
                implicitWidth: 320
                options: dc.devices.map(n => ({ label: page.nodeLabel(n), value: n.id }))
                value: dc.current ? dc.current.id : -1
                placeholder: "No devices"
                enabled: dc.devices.length > 0
                onPicked: v => dc.choose(dc.devices.find(n => n.id === v))
            }
        }

        RowLayout {
            visible: dc.current !== null && dc.current.audio !== null
            Layout.fillWidth: true
            spacing: 12

            Btn {
                readonly property bool muted: dc.current && dc.current.audio ? dc.current.audio.muted : false
                icon: dc.kind === "output" ? (muted ? "volume-x" : "volume") : (muted ? "mic-off" : "mic")
                variant: muted ? "normal" : "ghost"
                onClicked: dc.current.audio.muted = !muted
            }
            LSlider {
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.01
                value: dc.current && dc.current.audio ? dc.current.audio.volume : 0
                onMoved: dc.current.audio.volume = value
            }
            Txt {
                text: Math.round((dc.current && dc.current.audio ? dc.current.audio.volume : 0) * 100) + "%"
                strong: true
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 48
            }
        }
    }

    DeviceCard {
        kind: "output"
        devices: page.sinks
        current: page.sink
        onChoose: n => Pipewire.preferredDefaultAudioSink = n
    }

    DeviceCard {
        kind: "input"
        devices: page.sources
        current: page.source
        onChoose: n => Pipewire.preferredDefaultAudioSource = n
    }

    Card {
        title: "Volume keys"
        SettingRow {
            label: "Step"
            description: "How much each press of the volume keys changes the volume."
            Seg {
                options: [1, 2, 5, 10].map(n => ({ label: n + "%", value: String(n) }))
                value: Theme.conf.volume_step || "5"
                onPicked: v => Theme.setValue("volume_step", v)
            }
        }
    }
}
