pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// The laptop battery (UPower's combined "display device"), for the bar and
// quick settings. `present` is false on desktops and in most VMs.
Singleton {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev !== null && dev.ready && dev.isLaptopBattery && dev.isPresent
    // 0-1 (UPower reports a percentage; older Quickshell versions passed it on as 0-100)
    readonly property real level: !present ? 0 : dev.percentage > 1 ? dev.percentage / 100 : dev.percentage
    readonly property int percent: Math.round(level * 100)
    readonly property bool charging: present && (dev.state === UPowerDeviceState.Charging)
    readonly property bool full: present && (dev.state === UPowerDeviceState.FullyCharged || (!UPower.onBattery && percent >= 100))
    readonly property bool pluggedIn: present && !UPower.onBattery
    readonly property bool low: present && UPower.onBattery && percent <= 15

    function duration(secs) {
        const m = Math.round(secs / 60);
        if (m < 1) return "less than a minute";
        const h = Math.floor(m / 60), r = m % 60;
        return h > 0 ? h + " h" + (r > 0 ? " " + (r < 10 ? "0" : "") + r + " min" : "") : r + " min";
    }

    // "3 h 20 min left", "1 h 05 min until full", ...
    readonly property string estimate: {
        if (!present) return "";
        if (full) return "Fully charged";
        if (charging) return dev.timeToFull > 0 ? duration(dev.timeToFull) + " until full" : "Charging";
        if (pluggedIn) return "Plugged in, not charging";
        return dev.timeToEmpty > 0 ? duration(dev.timeToEmpty) + " left" : "Estimating time left…";
    }
}
