pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

// Volume, brightness and media keys (sxhkd calls these through
// `qs -c lumen ipc call media ...`), and the small on-screen display that
// shows the new level.
Singleton {
    id: root

    // ---- on-screen display ----
    property bool shown: false
    property string icon: "volume"
    property real level: 0        // 0..1
    property string label: ""

    function flash(icon, level, label) {
        root.icon = icon;
        root.level = level;
        root.label = label;
        shown = true;
        hide.restart();
    }
    Timer { id: hide; interval: 1400; onTriggered: root.shown = false }

    // ---- sound ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source].filter(o => o) }

    function showVolume() {
        if (!sink || !sink.audio) return;
        const v = sink.audio.volume;
        flash(sink.audio.muted || v === 0 ? "volume-x" : "volume", sink.audio.muted ? 0 : v,
              sink.audio.muted ? "Muted" : Math.round(v * 100) + "%");
    }
    // Volume keys change it by this much (Settings > Sound).
    readonly property real step: Math.max(1, Math.min(20, +(Theme.conf.volume_step || 5))) / 100

    function volume(step) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, Math.round((sink.audio.volume + step) * 100) / 100));
        showVolume();
    }
    function toggleMute() {
        if (!sink || !sink.audio) return;
        sink.audio.muted = !sink.audio.muted;
        showVolume();
    }
    function toggleMic() {
        if (!source || !source.audio) return;
        source.audio.muted = !source.audio.muted;
        flash(source.audio.muted ? "mic-off" : "mic", source.audio.muted ? 0 : source.audio.volume,
              source.audio.muted ? "Off" : "On");
    }

    // ---- screen brightness (built-in screens) ----
    function brightness(step) {
        if (!Brightness.available) return;
        Brightness.set(Brightness.value + step);
        flash("brightness", Brightness.value, Math.round(Brightness.value * 100) + "%");
    }

    // ---- media players (the one playing, else the first) ----
    readonly property var player: {
        const all = Mpris.players.values;
        return all.find(p => p.isPlaying) ?? all[0] ?? null;
    }
    function playPause() { if (player && player.canTogglePlaying) player.togglePlaying(); }
    function next() { if (player && player.canGoNext) player.next(); }
    function previous() { if (player && player.canGoPrevious) player.previous(); }
    function stop() { if (player && player.canControl) player.stop(); }
}
