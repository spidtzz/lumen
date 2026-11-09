import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Displays, like GNOME's: a picture of the screens on top (click one to pick
// it, drag to arrange them), that screen's settings below. Changes are tried
// first and undone after 15 seconds unless kept.
Page {
    id: page
    title: "Displays"
    description: "Resolution, refresh rate, orientation and arrangement. New settings are tried first and undone after 15 seconds unless you keep them."

    // Editable copy of Displays.outputs, with placement fields.
    property var draft: []
    property string savedDraft: ""
    property var revertArgs: []
    property bool confirming: false
    property int countdown: 15
    property string chosen: ""

    readonly property bool dirty: JSON.stringify(draft) !== savedDraft
    readonly property bool multi: draft.length > 1
    readonly property var sel: draft.find(o => o.name === chosen) ?? draft.find(o => o.primary) ?? draft[0] ?? null
    readonly property var selMode: sel ? sel.modes.find(m => m.size === sel.mode) ?? null : null
    readonly property var enabledOutputs: draft.filter(o => o.enabled && o.mode !== "")

    // ---- names and labels ----
    function friendly(n) {
        if (/^(eDP|LVDS|DSI)/i.test(n)) return "Built-in display";
        if (/^HDMI/i.test(n)) return "HDMI";
        if (/^(DP|DisplayPort)/i.test(n)) return "DisplayPort";
        if (/^DVI/i.test(n)) return "DVI";
        if (/^VGA/i.test(n)) return "VGA";
        if (/^(Virtual|qxl|virtio)/i.test(n)) return "Virtual display";
        return n;
    }
    function aspect(size) {
        const m = /^(\d+)x(\d+)$/.exec(size);
        if (!m) return "";
        const r = +m[1] / +m[2];
        const known = [[16 / 9, "16:9"], [16 / 10, "16:10"], [21 / 9, "21:9"], [32 / 9, "32:9"], [4 / 3, "4:3"], [5 / 4, "5:4"], [3 / 2, "3:2"]];
        for (const [v, name] of known)
            if (Math.abs(r - v) < 0.03) return name;
        return "";
    }
    function hz(r) {
        const v = +r;
        return (Math.abs(v - Math.round(v)) < 0.02 ? Math.round(v) : v.toFixed(2)) + " Hz";
    }
    // Width and height on screen (turned for portrait).
    function dims(o) {
        const m = /^(\d+)x(\d+)$/.exec(o.mode || (o.modes[0] ? o.modes[0].size : ""));
        const w = m ? +m[1] : 1920, h = m ? +m[2] : 1080;
        return (o.rotation === "left" || o.rotation === "right") ? [h, w] : [w, h];
    }

    // ---- editing ----
    function reset() {
        const d = JSON.parse(JSON.stringify(Displays.outputs));
        for (const o of d) { o.relation = ""; o.relativeTo = ""; }
        draft = d;
        savedDraft = JSON.stringify(d);
        if (!d.some(o => o.name === chosen))
            chosen = (d.find(o => o.primary) ?? d[0] ?? { name: "" }).name;
    }
    function edit(name, changes) {
        const d = JSON.parse(JSON.stringify(draft));
        const o = d.find(x => x.name === name);
        if (!o) return;
        Object.assign(o, changes);
        if (changes.primary === true)
            for (const x of d) if (x.name !== name) x.primary = false;
        draft = d;
    }
    // A screen dropped at (x, y), in pixels: put it against the nearest side
    // of another screen, lined up with its edge if close, then shift
    // everything so the top-left corner is 0,0 (xrandr wants no negatives).
    function place(name, x, y) {
        const d = JSON.parse(JSON.stringify(draft));
        const me = d.find(o => o.name === name);
        const others = d.filter(o => o.name !== name && o.enabled && o.mode !== "");
        if (!me || others.length === 0) return;
        const [w, h] = dims(me);
        let best = null;
        for (const o of others) {
            const [ow, oh] = dims(o);
            const snapY = Math.abs(y - o.y) < oh * 0.1 ? o.y : Math.max(o.y - h + 1, Math.min(o.y + oh - 1, y));
            const snapX = Math.abs(x - o.x) < ow * 0.1 ? o.x : Math.max(o.x - w + 1, Math.min(o.x + ow - 1, x));
            for (const c of [[o.x + ow, snapY], [o.x - w, snapY], [snapX, o.y + oh], [snapX, o.y - h]]) {
                const dist = Math.hypot(c[0] - x, c[1] - y);
                if (!best || dist < best.dist) best = { x: c[0], y: c[1], dist: dist };
            }
        }
        me.x = Math.round(best.x);
        me.y = Math.round(best.y);
        me.relation = "";
        const live = d.filter(o => o.enabled && o.mode !== "");
        const minX = Math.min(...live.map(o => o.x)), minY = Math.min(...live.map(o => o.y));
        for (const o of live) { o.x -= minX; o.y -= minY; o.relation = ""; }
        draft = d;
    }

    function applyDraft() {
        revertArgs = Displays.buildArgs(Displays.outputs);
        Displays.apply(Displays.buildArgs(draft));
        confirming = true;
        countdown = 15;
    }
    function keep() {
        confirming = false;
        Displays.save(Displays.buildArgs(Displays.outputs));
    }
    function revert() {
        confirming = false;
        Displays.apply(revertArgs);
    }

    Connections {
        target: Displays
        function onOutputsChanged() { if (!page.confirming) page.reset(); }
        function onApplied(ok) { if (!ok) page.confirming = false; }
    }
    Component.onCompleted: { Displays.refresh(); reset(); }

    Timer {
        running: page.confirming
        interval: 1000
        repeat: true
        onTriggered: if (--page.countdown <= 0) page.revert()
    }

    // ---- keep or revert ----
    Card {
        visible: page.confirming
        highlight: true
        title: "Keep these display settings?"
        description: "Going back to the previous settings in " + page.countdown + " s."
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Theme.field
            Rectangle {
                width: parent.width * page.countdown / 15
                height: parent.height
                radius: 2
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
            }
        }
        RowLayout {
            spacing: 8
            Btn { text: "Keep changes"; variant: "primary"; onClicked: page.keep() }
            Btn { text: "Revert"; onClicked: page.revert() }
        }
    }

    Card {
        visible: Displays.lastError !== ""
        title: "Couldn't apply"
        description: Displays.lastError
    }

    Txt {
        visible: Displays.loaded && page.draft.length === 0
        text: "No screens found. Is xrandr installed?"
        muted: true
    }

    // ---- the arrangement ----
    Rectangle {
        id: stage
        visible: page.draft.length > 0
        Layout.fillWidth: true
        implicitHeight: 230
        radius: Theme.radius
        color: Theme.field
        border.width: 1
        border.color: Theme.line

        readonly property var live: page.enabledOutputs
        readonly property real minX: live.length ? Math.min(...live.map(o => o.x)) : 0
        readonly property real minY: live.length ? Math.min(...live.map(o => o.y)) : 0
        readonly property real maxX: live.length ? Math.max(...live.map(o => o.x + page.dims(o)[0])) : 1
        readonly property real maxY: live.length ? Math.max(...live.map(o => o.y + page.dims(o)[1])) : 1
        readonly property real pad: 28
        readonly property real scale: Math.min((width - pad * 2) / Math.max(1, maxX - minX), (height - pad * 2 - 18) / Math.max(1, maxY - minY))
        readonly property real offX: (width - (maxX - minX) * scale) / 2
        readonly property real offY: (height - 18 - (maxY - minY) * scale) / 2

        Repeater {
            model: stage.live
            delegate: Rectangle {
                id: screenRect
                required property var modelData
                readonly property var o: modelData
                readonly property bool picked: page.sel !== null && page.sel.name === o.name
                x: stage.offX + (o.x - stage.minX) * stage.scale
                y: stage.offY + (o.y - stage.minY) * stage.scale
                width: page.dims(o)[0] * stage.scale - 4
                height: page.dims(o)[1] * stage.scale - 4
                radius: Theme.r(8)
                color: picked ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.panel
                border.width: picked ? 2 : 1
                border.color: picked ? Theme.accent : Theme.line
                z: dragArea.drag.active ? 2 : 1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    width: parent.width - 12
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "monitor"
                        size: 18
                        color: screenRect.picked ? Theme.accent : Theme.muted
                        visible: screenRect.height > 70
                    }
                    Txt {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: page.friendly(screenRect.o.name)
                        strong: true
                        size: 13
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                    Txt {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: screenRect.o.mode.replace("x", " × ") + (screenRect.o.primary && page.multi ? "  ·  Primary" : "")
                        muted: true
                        size: 11
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        visible: screenRect.height > 50
                    }
                }

                MouseArea {
                    id: dragArea
                    property bool moved: false
                    anchors.fill: parent
                    cursorShape: page.multi ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
                    drag.target: page.multi && !page.confirming ? screenRect : null
                    drag.threshold: 4
                    onPressed: { moved = false; page.chosen = screenRect.o.name; }
                    onPositionChanged: if (drag.active) moved = true
                    onReleased: {
                        if (!moved) return;
                        moved = false;
                        page.place(screenRect.o.name,
                                   (screenRect.x - stage.offX) / stage.scale + stage.minX,
                                   (screenRect.y - stage.offY) / stage.scale + stage.minY);
                    }
                }
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: page.multi ? "Click a screen to change it · drag to match how they sit on your desk" : "This screen"
            muted: true
            size: 12
        }
    }

    // Screens that are turned off don't appear above; pick them here.
    Flow {
        visible: page.draft.some(o => !o.enabled)
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: page.draft.filter(o => !o.enabled)
            delegate: Btn {
                required property var modelData
                text: page.friendly(modelData.name) + " (off)"
                variant: page.sel && page.sel.name === modelData.name ? "primary" : "normal"
                onClicked: page.chosen = modelData.name
            }
        }
    }

    // ---- the chosen screen ----
    Card {
        visible: page.sel !== null
        title: page.sel ? page.friendly(page.sel.name) : ""
        description: !page.sel ? ""
            : page.sel.enabled ? page.sel.name + "  ·  " + page.sel.mode.replace("x", " × ") + " at " + page.hz(page.sel.rate)
            : page.sel.name + "  ·  turned off"

        SettingRow {
            visible: page.multi
            label: "Use this display"
            Toggle {
                checked: page.sel ? page.sel.enabled : false
                // the last screen that's on can't be turned off
                enabled: page.sel && (!page.sel.enabled || page.enabledOutputs.length > 1)
                onToggled: c => {
                    const o = page.sel;
                    const m = o.mode || (o.modes[0] ? o.modes[0].size : "");
                    const info = o.modes.find(x => x.size === m);
                    page.edit(o.name, { enabled: c, mode: m, rate: o.rate || (info ? info.rates[0] : "") });
                    if (c) {
                        // next to the others, on the right
                        const others = page.enabledOutputs.filter(x => x.name !== o.name);
                        const right = others.length ? Math.max(...others.map(x => x.x + page.dims(x)[0])) : 0;
                        page.edit(o.name, { x: right, y: 0 });
                    }
                }
            }
        }

        SettingRow {
            visible: page.sel !== null && page.sel.enabled
            label: "Resolution"
            Dropdown {
                implicitWidth: 260
                options: page.sel ? page.sel.modes.map(m => ({
                    label: m.size.replace("x", " × ") + (page.aspect(m.size) ? "  (" + page.aspect(m.size) + ")" : "") + (m.preferred ? "  ★" : ""),
                    value: m.size
                })) : []
                value: page.sel ? page.sel.mode : ""
                onPicked: v => {
                    const info = page.sel.modes.find(m => m.size === v);
                    page.edit(page.sel.name, { mode: v, rate: info.rates.includes(page.sel.rate) ? page.sel.rate : info.rates[0] });
                }
            }
        }

        SettingRow {
            visible: page.sel !== null && page.sel.enabled && page.selMode !== null && page.selMode.rates.length > 1
            label: "Refresh rate"
            description: "Higher is smoother."
            Dropdown {
                implicitWidth: 260
                options: page.selMode ? page.selMode.rates.slice().sort((a, b) => +b - +a).map(r => ({ label: page.hz(r), value: r })) : []
                value: page.sel ? page.sel.rate : ""
                onPicked: v => page.edit(page.sel.name, { rate: v })
            }
        }

        SettingRow {
            visible: page.sel !== null && page.sel.enabled
            label: "Orientation"
            Dropdown {
                implicitWidth: 260
                options: [
                    { label: "Landscape", value: "normal" },
                    { label: "Portrait (turned left)", value: "left" },
                    { label: "Portrait (turned right)", value: "right" },
                    { label: "Landscape (upside down)", value: "inverted" }
                ]
                value: page.sel ? page.sel.rotation : "normal"
                onPicked: v => page.edit(page.sel.name, { rotation: v })
            }
        }

        SettingRow {
            visible: page.multi && page.sel !== null && page.sel.enabled
            label: "Primary display"
            description: "Where the login screen and new windows appear first."
            Toggle {
                checked: page.sel ? page.sel.primary : false
                enabled: page.sel && !page.sel.primary
                onToggled: c => page.edit(page.sel.name, { primary: c })
            }
        }

        SettingRow {
            id: mirrorRow
            visible: page.multi && page.sel !== null && page.sel.enabled && !page.sel.primary
            readonly property var main: page.draft.find(x => x.primary && x.name !== (page.sel ? page.sel.name : "")) ?? page.draft.find(x => x.name !== (page.sel ? page.sel.name : ""))
            label: "Mirror"
            description: main ? "Show the same picture as " + page.friendly(main.name) + "." : ""
            Toggle {
                checked: page.sel ? page.sel.relation === "same-as" : false
                onToggled: c => page.edit(page.sel.name, c ? { relation: "same-as", relativeTo: mirrorRow.main.name } : { relation: "", relativeTo: "" })
            }
        }
    }

    // ---- actions ----
    RowLayout {
        visible: page.draft.length > 0
        spacing: 8
        Layout.fillWidth: true
        Btn {
            text: "Apply"
            variant: "primary"
            enabled: page.dirty && !page.confirming
            busy: Displays.applying
            onClicked: page.applyDraft()
        }
        Btn { text: "Undo changes"; enabled: page.dirty && !page.confirming; onClicked: page.reset() }
        Item { Layout.fillWidth: true }
        Btn { icon: "refresh"; text: "Detect"; variant: "ghost"; onClicked: Displays.refresh() }
        Btn { text: "Reset to automatic"; variant: "ghost"; enabled: !page.confirming; onClicked: Displays.resetAutomatic() }
    }

    Txt {
        Layout.fillWidth: true
        text: "In a virtual machine, the window size sets the resolution while clipboard sharing (spice-vdagent) runs."
        muted: true
        size: 12
    }
}
