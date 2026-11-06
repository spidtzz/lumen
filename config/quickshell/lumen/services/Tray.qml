pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

// Tray icons (StatusNotifierItem), plus your pins and custom icons from
// ~/.config/lumen/tray.json.
Singleton {
    id: root

    readonly property var items: SystemTray.items.values
    readonly property var pinned: adapter.pinned
    readonly property var icons: adapter.icons

    function isPinned(id) { return adapter.pinned.includes(id); }

    function setPinned(id, on) {
        const p = adapter.pinned.filter(x => x !== id);
        if (on) p.push(id);
        adapter.pinned = p;
    }

    // Custom icon: an icon-theme name or an absolute image path. "" resets it.
    function setIcon(id, icon) {
        const m = Object.assign({}, adapter.icons);
        if (icon && icon.trim() !== "") m[id] = icon.trim();
        else delete m[id];
        adapter.icons = m;
    }

    function iconFor(item) {
        const o = adapter.icons[item.id];
        if (o)
            return o.startsWith("/") ? "file://" + o : Quickshell.iconPath(o, "image-missing");
        return item.icon;
    }

    FileView {
        id: file
        path: Theme.configHome + "/lumen/tray.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            property list<string> pinned: []
            property var icons: ({})
        }
    }
}
