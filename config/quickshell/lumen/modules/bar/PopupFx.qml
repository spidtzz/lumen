import QtQuick
import qs.services

// A bar popup's entrance: fades in and glides out of the bar while growing
// slightly; closing plays it back. `on` opens it; `t` is how far along it is.
Item {
    id: fx

    property var bar
    property bool on: false
    property var content: null

    property real t: on ? 1 : 0
    Behavior on t { NumberAnimation { duration: fx.t < 0.5 ? Theme.animNormal : Theme.animFast; easing.type: fx.t < 0.5 ? Theme.easeOut : Theme.easeIn } }
    readonly property real slide: (1 - t) * 10
    readonly property string edge: bar ? bar.edge : "top"
    width: content ? content.implicitWidth : 0
    height: content ? content.implicitHeight : 0
    opacity: t
    // Fully closed: not drawn at all.
    visible: t > 0.001
    transform: [
        Translate {
            x: fx.edge === "left" ? -fx.slide : fx.edge === "right" ? fx.slide : 0
            y: fx.edge === "top" ? -fx.slide : fx.edge === "bottom" ? fx.slide : 0
        },
        Scale {
            origin.x: fx.edge === "left" ? 0 : fx.edge === "right" ? fx.width : fx.width / 2
            origin.y: fx.edge === "top" ? 0 : fx.edge === "bottom" ? fx.height : fx.height / 2
            xScale: 0.96 + 0.04 * fx.t
            yScale: 0.96 + 0.04 * fx.t
        }
    ]
}
