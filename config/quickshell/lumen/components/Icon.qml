import QtQuick
import QtQuick.Shapes
import qs.services

// Line icons drawn as vector paths (24×24 grid, Feather style), so they need
// no icon theme and take any colour.
Item {
    id: root

    property string name
    property color color: Theme.ink
    property real size: 18
    property real stroke: 2

    implicitWidth: size
    implicitHeight: size

    readonly property var paths: ({
        "crop": "M6.13 1L6 16a2 2 0 0 0 2 2h15 M1 6.13L16 6a2 2 0 0 1 2 2v15",
        "camera": "M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z M8 13a4 4 0 1 0 8 0a4 4 0 1 0-8 0",
        "record": "M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0 M9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0",
        "bluetooth": "M6.5 6.5l11 11L12 23V1l5.5 5.5-11 11",
        "gauge": "M12 14l4-4 M3.34 19a10 10 0 1 1 17.32 0",
        "brightness": "M8 12a4 4 0 1 0 8 0a4 4 0 1 0-8 0 M12 2v2 M12 20v2 M4.93 4.93l1.41 1.41 M17.66 17.66l1.41 1.41 M2 12h2 M20 12h2 M6.34 17.66l-1.41 1.41 M19.07 4.93l-1.41 1.41",
        "command": "M18 3a3 3 0 0 0-3 3v12a3 3 0 0 0 3 3 3 3 0 0 0 3-3 3 3 0 0 0-3-3H6a3 3 0 0 0-3 3 3 3 0 0 0 3 3 3 3 0 0 0 3-3V6a3 3 0 0 0-3-3 3 3 0 0 0-3 3 3 3 0 0 0 3 3h12a3 3 0 0 0 3-3 3 3 0 0 0-3-3z",
        "lumen": "M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0 M10 12a2 2 0 1 0 4 0a2 2 0 1 0-4 0 M12 3v2.5 M12 18.5v2.5",
        "layout": "M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z M3 9h18",
        "power": "M18.36 6.64a9 9 0 1 1-12.73 0 M12 2v10",
        "log-out": "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4 M16 17l5-5-5-5 M21 12H9",
        "restart": "M1 4v6h6 M3.51 15a9 9 0 1 0 2.13-9.36L1 10",
        "moon": "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z",
        "sun": "M7 12a5 5 0 1 0 10 0a5 5 0 1 0-10 0 M12 1v2 M12 21v2 M4.22 4.22l1.42 1.42 M18.36 18.36l1.42 1.42 M1 12h2 M21 12h2 M4.22 19.78l1.42-1.42 M18.36 5.64l1.42-1.42",
        "bell": "M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9 M13.73 21a2 2 0 0 1-3.46 0",
        "bell-off": "M13.73 21a2 2 0 0 1-3.46 0 M18.63 13A17.89 17.89 0 0 1 18 8 M6.26 6.26A5.86 5.86 0 0 0 6 8c0 7-3 9-3 9h14 M18 8a6 6 0 0 0-9.33-5 M1 1l22 22",
        "chevron-left": "M15 18l-6-6 6-6",
        "chevron-up": "M18 15l-6-6-6 6",
        "calendar": "M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z M16 2v4 M8 2v4 M3 10h18",
        "trash": "M3 6h18 M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6 M10 11v6 M14 11v6 M9 6V4h6v2",
        "pin": "M12 17v5 M5 17h14l-2-4V7l1-3H6l1 3v6z",
        "cpu": "M6 4h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z M9 9h6v6H9z M9 1v3 M15 1v3 M9 20v3 M15 20v3 M20 9h3 M20 14h3 M1 9h3 M1 14h3",
        "folder": "M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z",
        "app": "M4 4h6v6H4z M14 4h6v6h-6z M4 14h6v6H4z M14 14h6v6h-6z",
        "droplet": "M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z",
        "monitor": "M4 3h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z M8 21h8 M12 17v4",
        "volume": "M11 5L6 9H2v6h4l5 4V5z M19.07 4.93a10 10 0 0 1 0 14.14 M15.54 8.46a5 5 0 0 1 0 7.07",
        "volume-x": "M11 5L6 9H2v6h4l5 4V5z M23 9l-6 6 M17 9l6 6",
        "mic": "M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z M19 10v2a7 7 0 0 1-14 0v-2 M12 19v4 M8 23h8",
        "mic-off": "M1 1l22 22 M9 9v3a3 3 0 0 0 5.12 2.12 M15 9.34V4a3 3 0 0 0-5.94-.6 M17 16.95A7 7 0 0 1 5 12v-2 M19 10v2a7 7 0 0 1-.11 1.23 M12 19v4 M8 23h8",
        "wifi": "M5 12.55a11 11 0 0 1 14.08 0 M1.42 9a16 16 0 0 1 21.16 0 M8.53 16.11a6 6 0 0 1 6.95 0 M12 20h.01",
        "ethernet": "M3 7h18v10H3z M7 17v-3 M11 17v-3 M15 17v-3 M19 17v-3",
        "keyboard": "M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z M6 8h.01 M10 8h.01 M14 8h.01 M18 8h.01 M6 12h.01 M10 12h.01 M14 12h.01 M18 12h.01 M7 16h10",
        "clock": "M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0 M12 6v6l4 2",
        "user": "M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2 M8 7a4 4 0 1 0 8 0a4 4 0 1 0-8 0",
        "info": "M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0 M12 16v-4 M12 8h.01",
        "chevron-down": "M6 9l6 6 6-6",
        "chevron-right": "M9 18l6-6-6-6",
        "check": "M20 6L9 17l-5-5",
        "x": "M18 6L6 18 M6 6l12 12",
        "plus": "M12 5v14 M5 12h14",
        "minus": "M5 12h14",
        "refresh": "M23 4v6h-6 M1 20v-6h6 M3.51 9a9 9 0 0 1 14.85-3.36L23 10 M1 14l4.64 4.36A9 9 0 0 0 20.49 15",
        "lock": "M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z M7 11V7a5 5 0 0 1 10 0v4",
        "search": "M3 11a8 8 0 1 0 16 0a8 8 0 1 0-16 0 M21 21l-4.35-4.35",
        "image": "M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z M8.5 8.5h.01 M21 15l-5-5L5 21",
        "copy": "M11 9h9a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-9a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2z M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1",
        "settings": "M9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0 M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"
    })

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.paths[root.name] || "" }
        }
    }
}
