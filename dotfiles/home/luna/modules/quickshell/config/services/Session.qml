pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs

// Session actions for the power menu, plus uptime.
Singleton {
    id: root

    // Boot time is read once from /proc/uptime; the uptime label is then
    // derived from the clock, which only ticks while the panel is open.
    property real bootTime: 0
    readonly property string uptime: {
        if (bootTime <= 0)
            return "";
        const total = Math.max(0, Math.floor((clock.date.getTime() - bootTime) / 1000));
        const d = Math.floor(total / 86400);
        const h = Math.floor(total % 86400 / 3600);
        const m = Math.floor(total % 3600 / 60);
        return "up " + (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "m";
    }

    function lock(): void {
        ShellState.closePanel();
        Quickshell.execDetached(Config.lockCommand);
    }

    function logout(): void {
        Hyprland.dispatch("exit");
    }

    function reboot(): void {
        Quickshell.execDetached(Config.rebootCommand);
    }

    function poweroff(): void {
        Quickshell.execDetached(Config.poweroffCommand);
    }

    SystemClock {
        id: clock

        enabled: ShellState.panelOpen
        precision: SystemClock.Minutes
    }

    FileView {
        path: "/proc/uptime"
        onLoaded: root.bootTime = Date.now() - parseFloat(text().split(" ")[0]) * 1000
    }
}
