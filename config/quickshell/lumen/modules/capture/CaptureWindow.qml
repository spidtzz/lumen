import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// Screenshot and recording overlay (Print), like GNOME's and Windows'
// Snipping Tool: the screen stays still under a dimmed layer, a toolbar at
// the bottom picks Area / Window / Screen and photo or video, and the shutter
// (or Enter) takes it. Area: drag to select, drag inside to move, corners to
// resize. Window and Screen: click to take it. It opens the way it was left
// last time (Capture keeps the choices in settings.conf).
// A normal window so it gets the keyboard (bspwmrc rule "lumen Capture" makes
// it fullscreen on the focused monitor).
FloatingWindow {
    id: win

    title: "lumen Capture"
    color: "#000000"

    readonly property var info: Capture.info
    readonly property var mon: info ? info.monitor : ({ name: "", x: 0, y: 0, w: 1280, h: 800 })
    implicitWidth: mon.w
    implicitHeight: mon.h

    readonly property string mode: Capture.mode       // shot | record
    readonly property string target: Capture.target   // area | window | screen
    readonly property bool video: mode === "record"
    readonly property bool stopping: video && Recorder.recording
    property bool optionsOpen: false

    // ---- geometry (in this window's coordinates; the monitor's are + mon.x/y) ----
    property rect sel
    readonly property var windows: info ? info.windows.filter(w => w.w > 0 && w.h > 0
        && w.x < mon.x + mon.w && w.x + w.w > mon.x && w.y < mon.y + mon.h && w.y + w.h > mon.y) : []
    property var hover: windows.find(w => w.id === info.focused) ?? (windows.length ? windows[windows.length - 1] : null)

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
    function winRect(w) {
        if (!w) return Qt.rect(0, 0, 0, 0);
        const x1 = clamp(w.x - mon.x, 0, mon.w), y1 = clamp(w.y - mon.y, 0, mon.h);
        const x2 = clamp(w.x + w.w - mon.x, 0, mon.w), y2 = clamp(w.y + w.h - mon.y, 0, mon.h);
        return Qt.rect(x1, y1, x2 - x1, y2 - y1);
    }
    function windowAt(x, y) {
        const gx = x + mon.x, gy = y + mon.y;
        for (let i = windows.length - 1; i >= 0; i--) {
            const w = windows[i];
            if (gx >= w.x && gx < w.x + w.w && gy >= w.y && gy < w.y + w.h) return w;
        }
        return null;
    }
    // The last area, if it's on this monitor; otherwise the middle of the screen.
    function initialArea() {
        const m = /^(\d+)x(\d+)\+(-?\d+)\+(-?\d+)$/.exec(Capture.area);
        if (m) {
            const r = Qt.rect(+m[3] - mon.x, +m[4] - mon.y, +m[1], +m[2]);
            if (r.x >= 0 && r.y >= 0 && r.width >= 8 && r.height >= 8 && r.x + r.width <= mon.w && r.y + r.height <= mon.h)
                return r;
        }
        return Qt.rect(Math.round(mon.w / 4), Math.round(mon.h / 4), Math.round(mon.w / 2), Math.round(mon.h / 2));
    }
    function geo(r) {
        return Math.round(r.width) + "x" + Math.round(r.height) + "+" + Math.round(r.x + mon.x) + "+" + Math.round(r.y + mon.y);
    }
    // Remembered for next time (once the area stops changing).
    function saveArea() { saveTimer.restart(); }
    Timer { id: saveTimer; interval: 400; onTriggered: Capture.set("area", win.geo(win.sel)) }

    // What's lit up: the area, the window under the pointer, or everything.
    readonly property rect hole: target === "area" ? sel : target === "window" ? winRect(hover) : Qt.rect(0, 0, width, height)

    function close() { Capture.close(); }
    function setTarget(t) { optionsOpen = false; Capture.set("target", t); }
    function setMode(m) { Capture.set("mode", m); }
    function capture() {
        if (stopping) { Recorder.stop(); close(); return; }
        const args = [mode];
        if (target === "area") {
            if (sel.width < 2 || sel.height < 2) return;
            args.push("--geometry", geo(sel));
        } else if (target === "window") {
            if (!hover) return;
            // Recordings follow the window; screenshots take what's lit up.
            if (video) args.push("--window", String(hover.id));
            else args.push("--geometry", geo(winRect(hover)));
        } else if (video && mon.name !== "") {
            args.push("--monitor", mon.name);
        } else {
            args.push("--geometry", geo(Qt.rect(0, 0, mon.w, mon.h)));
        }
        if (Capture.delay > 0) args.push("--delay", String(Capture.delay));
        args.push(Capture.pointer ? "--pointer" : "--no-pointer");
        if (!video) args.push(Capture.save ? "--save" : "--copy");
        else if (Capture.audio) args.push("--audio");
        Capture.run(args);
    }

    // ---- the still picture of the screen ----
    Image {
        anchors.fill: parent
        source: win.info ? "file://" + win.info.image : ""
        sourceClipRect: Qt.rect(win.mon.x, win.mon.y, win.mon.w, win.mon.h)
        cache: false
        smooth: false
        fillMode: Image.Stretch
    }

    // ---- dim everything but the hole ----
    Item {
        id: shade
        anchors.fill: parent
        opacity: 0
        NumberAnimation on opacity { to: 1; duration: Theme.animNormal; easing.type: Theme.easeOut }
        readonly property color tint: Qt.rgba(0, 0, 0, win.target === "screen" ? 0.12 : 0.5)
        Rectangle { x: 0; y: 0; width: parent.width; height: Math.max(0, win.hole.y); color: shade.tint }
        Rectangle {
            x: 0; y: win.hole.y + win.hole.height
            width: parent.width; height: Math.max(0, parent.height - y); color: shade.tint
        }
        Rectangle { x: 0; y: win.hole.y; width: Math.max(0, win.hole.x); height: win.hole.height; color: shade.tint }
        Rectangle {
            x: win.hole.x + win.hole.width; y: win.hole.y
            width: Math.max(0, parent.width - x); height: win.hole.height; color: shade.tint
        }
    }

    // ---- outline, handles and labels ----
    Rectangle {
        id: frame
        visible: win.hole.width > 0 && win.hole.height > 0
        x: win.hole.x - (win.target === "screen" ? 0 : 2)
        y: win.hole.y - (win.target === "screen" ? 0 : 2)
        width: win.hole.width + (win.target === "screen" ? 0 : 4)
        height: win.hole.height + (win.target === "screen" ? 0 : 4)
        color: "transparent"
        border.width: win.target === "screen" ? 4 : 2
        border.color: win.video ? Theme.danger : Theme.accent
        radius: win.target === "window" ? Theme.r(6) : 0
        Behavior on x { enabled: win.target === "window"; NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
        Behavior on y { enabled: win.target === "window"; NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
        Behavior on width { enabled: win.target === "window"; NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
        Behavior on height { enabled: win.target === "window"; NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
    }

    Repeater {
        model: win.target === "area" ? ["tl", "tr", "bl", "br"] : []
        delegate: Rectangle {
            required property string modelData
            width: 14; height: 14
            radius: Theme.r(7)
            x: (modelData[1] === "l" ? win.sel.x : win.sel.x + win.sel.width) - width / 2
            y: (modelData[0] === "t" ? win.sel.y : win.sel.y + win.sel.height) - height / 2
            color: Theme.panel
            border.width: 2
            border.color: frame.border.color
        }
    }

    // size (area) or app name (window), above the top-left corner
    Rectangle {
        visible: (win.target === "area" || (win.target === "window" && win.hover !== null)) && win.hole.width > 0
        x: win.clamp(win.hole.x, 8, win.width - width - 8)
        y: win.hole.y - height - 10 >= 8 ? win.hole.y - height - 10 : win.hole.y + 10
        width: label.implicitWidth + 16
        height: 26
        radius: Theme.r(8)
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        Txt {
            id: label
            anchors.centerIn: parent
            size: 12
            strong: true
            font.features: ({ "tnum": 1 })
            text: win.target === "area"
                ? Math.round(win.sel.width) + " × " + Math.round(win.sel.height)
                : (win.hover ? (win.hover.name || "Window") + "  ·  " + Math.round(win.hole.width) + " × " + Math.round(win.hole.height) : "")
        }
    }

    // ---- the mouse on the screen ----
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property string drag: ""   // new | move | tl | tr | bl | br (area only)
        property real px: 0
        property real py: 0
        property rect start
        property string over: ""   // handle or "move" under the pointer

        function handleAt(x, y) {
            const s = win.sel, d = 12;
            const l = Math.abs(x - s.x) <= d, r = Math.abs(x - s.x - s.width) <= d;
            const t = Math.abs(y - s.y) <= d, b = Math.abs(y - s.y - s.height) <= d;
            if (t && l) return "tl";
            if (t && r) return "tr";
            if (b && l) return "bl";
            if (b && r) return "br";
            if (x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height) return "move";
            return "";
        }

        cursorShape: win.target !== "area" ? Qt.PointingHandCursor
            : (drag || over) === "move" ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
            : (drag || over) === "tl" || (drag || over) === "br" ? Qt.SizeFDiagCursor
            : (drag || over) === "tr" || (drag || over) === "bl" ? Qt.SizeBDiagCursor
            : Qt.CrossCursor

        onPressed: m => {
            win.optionsOpen = false;
            if (m.button === Qt.RightButton) { win.close(); return; }
            if (win.target !== "area") return;
            px = m.x; py = m.y; start = win.sel;
            drag = handleAt(m.x, m.y) || "new";
        }
        onPositionChanged: m => {
            if (win.target === "window") {
                const w = win.windowAt(m.x, m.y);
                if (w) win.hover = w;
                return;
            }
            if (win.target !== "area") return;
            if (!pressed || drag === "") { over = handleAt(m.x, m.y); return; }
            const W = win.width, H = win.height;
            const x = win.clamp(m.x, 0, W), y = win.clamp(m.y, 0, H);
            const dx = x - px, dy = y - py;
            if (drag === "new") {
                win.sel = Qt.rect(Math.min(px, x), Math.min(py, y), Math.abs(x - px), Math.abs(y - py));
            } else if (drag === "move") {
                win.sel = Qt.rect(win.clamp(start.x + dx, 0, W - start.width), win.clamp(start.y + dy, 0, H - start.height),
                                  start.width, start.height);
            } else {
                let l = start.x, t = start.y, r = start.x + start.width, b = start.y + start.height;
                if (drag.includes("l")) l += dx; else r += dx;
                if (drag.includes("t")) t += dy; else b += dy;
                l = win.clamp(l, 0, W); r = win.clamp(r, 0, W); t = win.clamp(t, 0, H); b = win.clamp(b, 0, H);
                win.sel = Qt.rect(Math.min(l, r), Math.min(t, b), Math.abs(r - l), Math.abs(b - t));
            }
        }
        onReleased: m => {
            if (drag === "") return;
            // A click without a drag keeps the area that was there.
            if (drag === "new" && (win.sel.width < 6 || win.sel.height < 6)) win.sel = start;
            drag = "";
            over = handleAt(m.x, m.y);
            win.saveArea();
        }
        onClicked: m => {
            if (m.button === Qt.LeftButton && win.target !== "area") {
                if (win.target === "window") win.hover = win.windowAt(m.x, m.y) ?? win.hover;
                win.capture();
            }
        }
        onDoubleClicked: m => {
            if (win.target === "area" && handleAt(m.x, m.y) === "move") win.capture();
        }
    }

    // ---- hint, top middle ----
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        width: hint.implicitWidth + 28
        height: 34
        radius: Theme.r(17)
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        opacity: 0.94
        MouseArea { anchors.fill: parent }
        Txt {
            id: hint
            anchors.centerIn: parent
            size: 13
            text: {
                const what = win.stopping ? "Enter stops the recording"
                    : win.target === "area" ? "Drag to select an area · Enter to " + (win.video ? "record" : "capture")
                    : win.target === "window" ? "Click a window to " + (win.video ? "record" : "capture") + " it"
                    : "Click anywhere to " + (win.video ? "record" : "capture") + " the screen";
                const wait = Capture.delay > 0 && !win.stopping ? " · " + Capture.delay + " s delay" : "";
                return what + wait + " · Esc to cancel";
            }
        }
    }

    // ---- options, above the toolbar ----
    Rectangle {
        id: options
        visible: win.optionsOpen
        anchors.horizontalCenter: bar.horizontalCenter
        anchors.bottom: bar.top
        anchors.bottomMargin: 10
        width: 440
        height: optCol.implicitHeight + 28
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        MouseArea { anchors.fill: parent }   // clicks here don't reach the screen

        ColumnLayout {
            id: optCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            SettingRow {
                label: "Delay"
                Seg {
                    implicitWidth: 200
                    options: [{ label: "None", value: 0 }, { label: "3 s", value: 3 }, { label: "5 s", value: 5 }, { label: "10 s", value: 10 }]
                    value: Capture.delay
                    onPicked: v => Capture.set("delay", v)
                }
            }
            SettingRow {
                label: "Show the pointer"
                Toggle { checked: Capture.pointer; onToggled: c => Capture.set("pointer", c) }
            }
            SettingRow {
                visible: !win.video
                label: "Screenshots"
                description: Capture.save ? "Copied, and saved to Pictures/Screenshots." : "Copied to the clipboard only."
                Seg {
                    implicitWidth: 200
                    options: [{ label: "Copy", value: false }, { label: "Copy & save", value: true }]
                    value: Capture.save
                    onPicked: v => Capture.set("save", v)
                }
            }
            SettingRow {
                visible: win.video
                label: "Record sound"
                description: "What your speakers play. Recordings go to Videos/Captures."
                Toggle { checked: Capture.audio; onToggled: c => Capture.set("audio", c) }
            }
        }
    }

    // ---- toolbar, bottom middle ----
    component ToolButton: Rectangle {
        id: tb
        property string icon
        property string text
        property bool selected: false
        property color selColor: Theme.accent
        signal clicked()
        implicitWidth: text !== "" ? 76 : 40
        implicitHeight: text !== "" ? 52 : 40
        radius: Theme.r(10)
        color: selected ? selColor : tbHover.hovered ? Theme.field : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
        Column {
            anchors.centerIn: parent
            spacing: 4
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: tb.icon
                size: 18
                color: tb.selected ? Theme.accentFg : Theme.ink
            }
            Txt {
                visible: tb.text !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                text: tb.text
                size: 11
                strong: true
                color: tb.selected ? Theme.accentFg : Theme.ink
            }
        }
        HoverHandler { id: tbHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: tb.clicked() }
    }
    component Divider: Rectangle { implicitWidth: 1; implicitHeight: 36; color: Theme.line }

    Rectangle {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        width: row.implicitWidth + 20
        height: 72
        radius: Theme.r(18)
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        opacity: 0
        NumberAnimation on opacity { to: 1; duration: Theme.animSlow; easing.type: Theme.easeOut }
        transform: Translate {
            y: 24
            NumberAnimation on y { to: 0; duration: Theme.animSlow; easing.type: Theme.easeOut }
        }
        MouseArea { anchors.fill: parent }   // clicks here don't reach the screen

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 10

            Row {
                spacing: 4
                ToolButton { icon: "crop"; text: "Area"; selected: win.target === "area"; onClicked: win.setTarget("area") }
                ToolButton { icon: "layout"; text: "Window"; selected: win.target === "window"; onClicked: win.setTarget("window") }
                ToolButton { icon: "monitor"; text: "Screen"; selected: win.target === "screen"; onClicked: win.setTarget("screen") }
            }

            Divider {}

            // shutter
            Rectangle {
                id: shutter
                implicitWidth: 56
                implicitHeight: 56
                radius: 28
                color: "transparent"
                border.width: 3
                border.color: shutterHover.hovered ? (win.video ? Theme.danger : Theme.accent) : Theme.ink
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                Rectangle {
                    anchors.centerIn: parent
                    width: win.stopping ? 20 : 42
                    height: width
                    radius: win.stopping ? Theme.r(4) : width / 2
                    color: win.video ? Theme.danger : Theme.ink
                    scale: shutterTap.pressed ? 0.88 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeInOut } }
                    Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                }
                HoverHandler { id: shutterHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: shutterTap; onTapped: win.capture() }
            }

            Divider {}

            // photo / video
            Rectangle {
                implicitWidth: modeRow.implicitWidth + 8
                implicitHeight: 48
                radius: Theme.r(12)
                color: Theme.field
                border.width: 1
                border.color: Theme.line
                Row {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 4
                    ToolButton { icon: "camera"; selected: !win.video; onClicked: win.setMode("shot") }
                    ToolButton { icon: "video"; selected: win.video; selColor: Theme.danger; onClicked: win.setMode("record") }
                }
            }

            ToolButton { icon: "sliders"; selected: win.optionsOpen; onClicked: win.optionsOpen = !win.optionsOpen }
            ToolButton { icon: "x"; onClicked: win.close() }
        }
    }

    // ---- keyboard ----
    Item {
        id: keys
        focus: true
        readonly property bool active: Window.active
        property bool wasActive: false
        onActiveChanged: {
            if (active) { wasActive = true; keys.forceActiveFocus(); }
            else if (wasActive) win.close();
        }
        Keys.onPressed: event => {
            const k = event.key, step = event.modifiers & Qt.ShiftModifier ? 10 : 1;
            if (k === Qt.Key_Escape) { win.optionsOpen ? (win.optionsOpen = false) : win.close(); }
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) win.capture();
            else if (k === Qt.Key_1 || k === Qt.Key_A) win.setTarget("area");
            else if (k === Qt.Key_2 || k === Qt.Key_W) win.setTarget("window");
            else if (k === Qt.Key_3 || k === Qt.Key_S) win.setTarget("screen");
            else if (k === Qt.Key_Tab || k === Qt.Key_V) win.setMode(win.video ? "shot" : "record");
            else if (k === Qt.Key_O) win.optionsOpen = !win.optionsOpen;
            else if (win.target === "area" && [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(k)) {
                const dx = k === Qt.Key_Left ? -step : k === Qt.Key_Right ? step : 0;
                const dy = k === Qt.Key_Up ? -step : k === Qt.Key_Down ? step : 0;
                win.sel = Qt.rect(win.clamp(win.sel.x + dx, 0, win.width - win.sel.width),
                                  win.clamp(win.sel.y + dy, 0, win.height - win.sel.height), win.sel.width, win.sel.height);
                win.saveArea();
            } else return;
            event.accepted = true;
        }
    }

    Component.onCompleted: {
        sel = initialArea();
        keys.forceActiveFocus();
    }
}
