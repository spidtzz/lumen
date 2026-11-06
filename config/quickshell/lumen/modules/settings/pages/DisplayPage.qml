import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Page {
    id: page
    title: "Displays"
    description: "Resolution, refresh rate, rotation and arrangement. Changes are tried first and undone unless you keep them."

    // Editable copy of Displays.outputs, with placement fields.
    property var draft: []
    property string baseline: ""
    property var revertArgs: []
    property bool confirming: false
    property int countdown: 15

    readonly property bool dirty: JSON.stringify(draft) !== baseline
    readonly property bool multi: draft.length > 1

    function reset() {
        const d = JSON.parse(JSON.stringify(Displays.outputs));
        for (const o of d) { o.relation = ""; o.relativeTo = ""; }
        draft = d;
        baseline = JSON.stringify(d);
    }

    function edit(name, changes) {
        const d = JSON.parse(JSON.stringify(draft));
        const o = d.find(x => x.name === name);
        Object.assign(o, changes);
        if (changes.primary === true)
            for (const x of d) if (x.name !== name) x.primary = false;
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

    Card {
        visible: page.confirming
        highlight: true
        title: "Keep these display settings?"
        description: "Reverting in " + page.countdown + " seconds."
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

    Repeater {
        model: page.draft

        delegate: Card {
            id: card
            required property var modelData
            readonly property var o: modelData
            readonly property var modeInfo: o.modes.find(m => m.size === o.mode)

            title: o.name + (o.primary ? "  ·  Primary" : "")
            description: o.enabled ? o.mode + " at " + Math.round(+o.rate) + " Hz" : "Turned off"

            SettingRow {
                visible: page.multi
                label: "Use this display"
                Toggle {
                    checked: card.o.enabled
                    onToggled: c => {
                        const m = card.o.mode || (card.o.modes[0] ? card.o.modes[0].size : "");
                        const info = card.o.modes.find(x => x.size === m);
                        page.edit(card.o.name, { enabled: c, mode: m, rate: card.o.rate || (info ? info.rates[0] : "") });
                    }
                }
            }

            SettingRow {
                visible: card.o.enabled
                label: "Resolution"
                Dropdown {
                    options: card.o.modes.map(m => ({ label: m.size.replace("x", " × ") + (m.preferred ? "  (recommended)" : ""), value: m.size }))
                    value: card.o.mode
                    onPicked: v => {
                        const info = card.o.modes.find(m => m.size === v);
                        page.edit(card.o.name, { mode: v, rate: info.rates.includes(card.o.rate) ? card.o.rate : info.rates[0] });
                    }
                }
            }

            SettingRow {
                visible: card.o.enabled
                label: "Refresh rate"
                Dropdown {
                    options: card.modeInfo ? card.modeInfo.rates.map(r => ({ label: (+r).toFixed(2) + " Hz", value: r })) : []
                    value: card.o.rate
                    onPicked: v => page.edit(card.o.name, { rate: v })
                }
            }

            SettingRow {
                visible: card.o.enabled
                label: "Rotation"
                Seg {
                    options: [
                        { label: "Normal", value: "normal" }, { label: "Left", value: "left" },
                        { label: "Right", value: "right" }, { label: "Upside down", value: "inverted" }
                    ]
                    value: card.o.rotation
                    onPicked: v => page.edit(card.o.name, { rotation: v })
                }
            }

            SettingRow {
                visible: card.o.enabled && page.multi
                label: "Primary display"
                description: "Where new windows and the login screen appear first."
                Toggle {
                    checked: card.o.primary
                    enabled: !card.o.primary
                    onToggled: c => page.edit(card.o.name, { primary: c })
                }
            }

            SettingRow {
                visible: card.o.enabled && page.multi && !card.o.primary
                label: "Position"
                Dropdown {
                    readonly property var primary: page.draft.find(x => x.primary) ?? page.draft.find(x => x.name !== card.o.name)
                    readonly property string target: primary ? primary.name : ""
                    options: [
                        { label: "Keep current position", value: "" },
                        { label: "Right of " + target, value: "right-of" },
                        { label: "Left of " + target, value: "left-of" },
                        { label: "Above " + target, value: "above" },
                        { label: "Below " + target, value: "below" },
                        { label: "Mirror " + target, value: "same-as" }
                    ]
                    value: card.o.relation
                    onPicked: v => page.edit(card.o.name, { relation: v, relativeTo: target })
                }
            }
        }
    }

    RowLayout {
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
        text: "In a virtual machine, the window size controls the resolution while clipboard sharing (spice-vdagent) is running."
        muted: true
        size: 12
    }
}
