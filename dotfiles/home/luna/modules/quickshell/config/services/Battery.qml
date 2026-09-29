pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    // False on desktops (or while UPower is not running).
    readonly property bool available: device.ready && device.isPresent && device.type === UPowerDeviceType.Battery
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged
    readonly property bool pluggedIn: !UPower.onBattery

    readonly property string icon: {
        if (charging || (pluggedIn && !full))
            return "battery_charging_full";
        if (full || percent >= 95)
            return "battery_full";
        if (percent <= 10)
            return "battery_alert";
        return "battery_" + Math.max(0, Math.min(6, Math.floor(percent / 100 * 7))) + "_bar";
    }

    readonly property string stateText: {
        if (full)
            return "Fully charged";
        if (charging)
            return device.timeToFull > 0 ? "Charging · " + formatDuration(device.timeToFull) + " until full" : "Charging";
        if (pluggedIn)
            return "Plugged in";
        return device.timeToEmpty > 0 ? formatDuration(device.timeToEmpty) + " left" : "On battery";
    }

    function formatDuration(seconds: real): string {
        const minutes = Math.round(seconds / 60);
        const h = Math.floor(minutes / 60);
        const m = minutes % 60;
        return h > 0 ? h + " h " + m + " min" : m + " min";
    }
}
