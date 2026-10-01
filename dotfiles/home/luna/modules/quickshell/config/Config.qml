pragma Singleton

import QtQuick
import Quickshell

// Behavior settings (timings, limits, commands). Visuals live in Theme.qml.
Singleton {
    // Workspace OSD
    readonly property int osdTimeout: 1200
    readonly property int osdMinWorkspaces: 5
    readonly property int osdMaxWorkspaces: 10

    // Notifications
    readonly property int popupTimeout: 5000
    // Upper bound for app-requested timeouts (ms).
    readonly property int popupMaxTimeout: 30000
    readonly property int popupMaxVisible: 4
    readonly property bool criticalPopupsStay: true
    // Notifications shown per app group before "Show more".
    readonly property int groupCollapsedCount: 2
    // Refresh rate of "5 min ago" labels while visible (ms).
    readonly property int relativeTimeInterval: 30000

    // Sliders: volume/brightness change per mouse wheel notch.
    readonly property real sliderWheelStep: 0.05

    // Clock and date. Swap the locale for e.g. Qt.locale("de_DE").
    readonly property var locale: Qt.locale("en_GB")
    readonly property string timeFormat: "HH:mm"
    readonly property string dateFormat: "dddd, d MMMM"

    // Night light color temperature in Kelvin (hyprsunset).
    readonly property int nightLightTemperature: 4000

    // App launcher
    // Entries shown under "Recent".
    readonly property int launcherRecentCount: 6
    // Icons per row in the app grids.
    readonly property int launcherColumns: 6
    readonly property int launcherMaxResults: 50
    // Days an unknown app keeps its "New" badge (unless launched earlier).
    readonly property int launcherNewDays: 3
    // Ranking bonus for pinned apps and the maximum usage (frecency) bonus.
    readonly property int launcherPinBonus: 150
    readonly property int launcherFrecencyBonus: 200
    // Half-life of the recency part of the frecency bonus (days).
    readonly property real launcherFrecencyHalfLife: 7
    // Terminal for Terminal=true entries; the command is appended.
    // Keep in sync with Hyprland's `terminal` variable (default-hyprland/vars.nix).
    readonly property var terminalCommand: ["ghostty", "-e"]
    // Fallback when the Claude Desktop app is not installed.
    readonly property string claudeDesktopId: "com.anthropic.Claude"
    readonly property var claudeWebCommand: ["xdg-open", "https://claude.ai"]
    readonly property var claudeCodeCommand: ["claude"]
    // "Ask Claude" from the launcher search opens a new chat with the
    // query and pasted images (qs-claude-ask); claude.ai without the app.
    readonly property var claudeAskCommand: ["qs-claude-ask"]
    readonly property var claudePasteCommand: ["qs-claude-paste"]
    readonly property string claudeAskWebUrl: "https://claude.ai/new"
    readonly property int claudeAskMaxChars: 2000

    // Claude plan usage (qs-claude-usage). Refreshed while the launcher is
    // open; older cached values are shown as unavailable.
    readonly property int usageRefreshInterval: 300000
    readonly property int usageMaxAge: 3600000
    // Bars switch to the warning color from this utilization on (0..1).
    readonly property real usageWarnThreshold: 0.8

    // Session actions
    readonly property var lockCommand: ["hyprlock"]
    readonly property var rebootCommand: ["systemctl", "reboot"]
    readonly property var poweroffCommand: ["systemctl", "poweroff"]
}
