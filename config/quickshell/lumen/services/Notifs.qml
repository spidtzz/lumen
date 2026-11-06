pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification server (replaces dunst/mako). Keeps a history for Quick
// Settings and a short list of popups shown in the corner.
Singleton {
    id: root

    property bool dnd: false
    // Newest first.
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    property var popups: []
    property var received: ({})   // notification id -> Date

    function dismissPopup(n) { popups = popups.filter(x => x !== n); }
    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
        popups = [];
    }
    function timeOf(n) {
        const t = received[n.id];
        if (!t) return "";
        const mins = Math.floor((Date.now() - t.getTime()) / 60000);
        if (mins < 1) return "now";
        if (mins < 60) return mins + " min";
        return Qt.formatTime(t, Theme.clock24h ? "HH:mm" : "h:mm AP");
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const r = Object.assign({}, root.received);
            r[n.id] = new Date();
            root.received = r;
            n.closed.connect(() => root.dismissPopup(n));
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n].concat(root.popups).slice(0, 4);
        }
    }
}
