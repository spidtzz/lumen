import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.services
import qs.components

Page {
    id: page
    title: "Sound"
    description: "Where sound plays, the microphone, and each app's volume."

    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    // Apps playing sound right now (their own volume).
    readonly property var apps: nodes.filter(n => n.audio && n.isStream && !n.isSink)

    function nodeLabel(n) { return n.description || n.nickname || n.name; }

    // Volume and mute state are only live for tracked nodes.
    PwObjectTracker { objects: page.sinks.concat(page.sources).concat(page.apps) }

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
            icon: dc.kind === "output" ? "speaker" : "mic"
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
        visible: Pipewire.ready
        title: "Apps"
        description: page.apps.length === 0 ? "Apps playing sound show up here, each with its own volume." : "Each app's own volume."

        Repeater {
            model: page.apps
            delegate: RowLayout {
                id: app
                required property var modelData
                readonly property var a: modelData.audio
                readonly property string appName: (modelData.properties || {})["application.name"] || modelData.description || modelData.name
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Theme.r(9)
                    color: Theme.field
                    Icon { anchors.centerIn: parent; name: "music"; size: 17; color: Theme.accent }
                }
                ColumnLayout {
                    Layout.preferredWidth: 170
                    spacing: 0
                    Txt { Layout.fillWidth: true; text: app.appName; strong: true; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                    Txt {
                        Layout.fillWidth: true
                        text: (app.modelData.properties || {})["media.name"] || ""
                        visible: text !== "" && text !== app.appName
                        muted: true; size: 11; elide: Text.ElideRight; wrapMode: Text.NoWrap
                    }
                }
                Btn {
                    icon: app.a && app.a.muted ? "volume-x" : "volume"
                    variant: app.a && app.a.muted ? "normal" : "ghost"
                    onClicked: app.a.muted = !app.a.muted
                }
                LSlider {
                    Layout.fillWidth: true
                    from: 0; to: 1; stepSize: 0.01
                    value: app.a ? app.a.volume : 0
                    onMoved: app.a.volume = value
                }
                Txt {
                    text: Math.round((app.a ? app.a.volume : 0) * 100) + "%"
                    strong: true
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 48
                }
            }
        }
    }

    Card {
        title: "Volume keys"
        SettingRow {
            icon: "volume"
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
