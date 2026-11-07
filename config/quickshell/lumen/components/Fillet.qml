import QtQuick
import QtQuick.Shapes

// A filled corner piece: an r×r square minus a quarter circle, so the
// filled part hugs the chosen corner ("top-left", "top-right",
// "bottom-left", "bottom-right"). Used for rounded screen corners (black)
// and the curved ends of an edge-to-edge bar (bar colour).
Shape {
    id: root

    property string corner: "top-left"
    property real r: 16
    property color fill: "black"

    width: r
    height: r
    preferredRendererType: Shape.CurveRenderer
    // Drawn for the top-left corner, then turned to the one asked for.
    transformOrigin: Item.Center
    rotation: ({ "top-left": 0, "top-right": 90, "bottom-right": 180, "bottom-left": 270 })[corner] ?? 0

    ShapePath {
        strokeWidth: -1
        fillColor: root.fill
        startX: 0; startY: 0
        PathLine { x: root.r; y: 0 }
        PathArc { x: 0; y: root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
        PathLine { x: 0; y: 0 }
    }
}
