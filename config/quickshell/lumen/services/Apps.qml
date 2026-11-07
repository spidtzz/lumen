pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Installed apps (.desktop files) for the launcher, ranked by how well they
// match and how often you open them (~/.local/state/lumen/launcher.json).
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .slice()
        .sort((a, b) => a.name.localeCompare(b.name))

    function uses(e) { return adapter.counts[e.id] || 0; }

    function score(e, q) {
        const name = e.name.toLowerCase();
        if (name === q) return 100;
        if (name.startsWith(q)) return 80;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 60;
        if (name.includes(q)) return 45;
        const extra = [e.genericName, e.comment, (e.keywords || []).join(" "), e.id]
            .join(" ").toLowerCase();
        if (extra.includes(q)) return 25;
        // Letters in order, e.g. "ffx" -> Firefox.
        let i = 0;
        for (const c of name) if (c === q[i]) i++;
        return i === q.length ? 10 : 0;
    }

    function search(text) {
        const q = text.trim().toLowerCase();
        if (q === "")
            return all.slice().sort((a, b) => (uses(b) - uses(a)) || a.name.localeCompare(b.name));
        return all
            .map(e => ({ e: e, s: score(e, q) }))
            .filter(x => x.s > 0)
            .sort((a, b) => (b.s - a.s) || (uses(b.e) - uses(a.e)) || a.e.name.localeCompare(b.e.name))
            .map(x => x.e);
    }

    function launch(e) {
        const c = Object.assign({}, adapter.counts);
        c[e.id] = (c[e.id] || 0) + 1;
        adapter.counts = c;
        // lumen's own Settings entry: open it directly.
        if (e.id === "lumen-settings")
            Panels.openSettings(Panels.settingsPage);
        else if (e.runInTerminal)
            Quickshell.execDetached(["kitty", "-e"].concat(e.command));
        else
            e.execute();
    }

    FileView {
        path: Theme.stateHome + "/lumen/launcher.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter(); }
        JsonAdapter {
            id: adapter
            property var counts: ({})
        }
    }
}
