pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Claude plan usage (session / weekly limit) from `qs-claude-usage`.
//
// That script calls the undocumented endpoint Claude Code uses for /usage;
// it may change or disappear at any time. It reads the OAuth token itself
// and only prints percentages and reset times, so no credential ever
// reaches QML or the log.
//
// No background polling: data is fetched when the launcher opens and the
// cache is older than Config.usageRefreshInterval, and periodically while
// it stays open. The last result is cached in ~/.cache/quickshell.
Singleton {
    id: root

    // { utilization: 0..1, resetsAt: ms since epoch (0 = unknown) } or null
    property var session: null
    property var week: null
    property real fetchedAt: 0
    property real lastAttempt: 0
    readonly property bool loading: fetchProc.running

    // Ticks while the launcher is open (reset countdowns, cache age).
    property real now: Date.now()

    readonly property bool available: fetchedAt > 0 && now - fetchedAt < Config.usageMaxAge && (session !== null || week !== null)

    readonly property string cachePath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quickshell/claude-usage.json"

    // Utilization of a window; a window whose reset time has passed is empty.
    function current(window: var): real {
        if (!window)
            return 0;
        if (window.resetsAt > 0 && window.resetsAt <= now)
            return 0;
        return window.utilization;
    }

    function refreshIfStale(): void {
        now = Date.now();
        if (now - lastAttempt >= Config.usageRefreshInterval)
            refresh();
    }

    // Logged out or the token was rejected: old numbers no longer belong
    // to anyone, drop them. ("expired" only means Claude Code hasn't
    // refreshed the token yet; the cache stays valid until usageMaxAge.)
    function forget(): void {
        session = null;
        week = null;
        fetchedAt = 0;
        cacheFile.setText("{}");
    }

    function refresh(): void {
        if (fetchProc.running)
            return;
        lastAttempt = Date.now();
        fetchProc.running = true;
    }

    function parseWindow(value: var): var {
        if (value === null || typeof value !== "object" || !Number.isFinite(value.utilization))
            return null;
        return {
            utilization: Math.max(0, value.utilization),
            resetsAt: Number.isFinite(value.resetsAt) ? value.resetsAt : 0
        };
    }

    function apply(data: var, fromCache: bool): bool {
        if (data === null || typeof data !== "object" || data.status !== "ok" || !Number.isFinite(data.fetchedAt))
            return false;
        const nextSession = parseWindow(data.session);
        const nextWeek = parseWindow(data.week);
        if (nextSession === null && nextWeek === null)
            return false;
        // An older cache must not replace a newer result.
        if (fromCache && data.fetchedAt <= fetchedAt)
            return false;
        session = nextSession;
        week = nextWeek;
        fetchedAt = data.fetchedAt;
        return true;
    }

    Timer {
        interval: Config.usageRefreshInterval
        repeat: true
        running: ShellState.launcherOpen
        onTriggered: root.refresh()
    }

    Timer {
        interval: Config.relativeTimeInterval
        repeat: true
        running: ShellState.launcherOpen
        onTriggered: root.now = Date.now()
    }

    Process {
        id: fetchProc

        command: ["qs-claude-usage"]
        stdout: StdioCollector {
            onStreamFinished: {
                let data = null;
                try {
                    data = JSON.parse(text);
                } catch (e) {}
                if (root.apply(data, false)) {
                    cacheFile.setText(JSON.stringify(data));
                    return;
                }
                if (["no-credentials", "bad-credentials", "http-401", "http-403"].includes(data?.reason))
                    root.forget();
                // Failed attempts are retried on the next open after a minute.
                root.lastAttempt = Math.min(root.lastAttempt, Date.now() - Config.usageRefreshInterval + 60000);
            }
        }
    }

    FileView {
        id: cacheFile

        path: root.cachePath
        printErrors: false
        onLoaded: {
            try {
                root.apply(JSON.parse(text()), true);
            } catch (e) {}
        }
    }
}
