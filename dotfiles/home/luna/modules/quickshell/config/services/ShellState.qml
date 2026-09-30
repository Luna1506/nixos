pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// UI state of the control center and the app launcher: whether they are
// open, on which screen, and which detail view is shown. At most one of the
// two is open at a time.
Singleton {
    id: root

    property bool panelOpen: false
    property ShellScreen panelScreen: null
    // "" (none), "wifi", "bluetooth" or "audio"
    property string detail: ""

    property bool launcherOpen: false
    property ShellScreen launcherScreen: null

    function focusedScreen(): ShellScreen {
        const name = Hyprland.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0] ?? null;
    }

    function openPanel(): void {
        if (panelOpen)
            return;
        const screen = focusedScreen();
        if (!screen)
            return;
        closeLauncher();
        panelScreen = screen;
        detail = "";
        panelOpen = true;
    }

    function closePanel(): void {
        panelOpen = false;
        detail = "";
    }

    function togglePanel(): void {
        panelOpen ? closePanel() : openPanel();
    }

    function openLauncher(): void {
        if (launcherOpen)
            return;
        const screen = focusedScreen();
        if (!screen)
            return;
        closePanel();
        launcherScreen = screen;
        launcherOpen = true;
    }

    function closeLauncher(): void {
        launcherOpen = false;
    }

    function toggleLauncher(): void {
        launcherOpen ? closeLauncher() : openLauncher();
    }

    readonly property var details: ["wifi", "bluetooth", "audio"]

    function openDetail(name: string): void {
        if (!details.includes(name)) {
            console.warn("ShellState: unknown detail view", name);
            return;
        }
        openPanel();
        detail = detail === name ? "" : name;
    }

    function closeDetail(): void {
        detail = "";
    }

    // Escape: close the detail view first, then the panel.
    function back(): void {
        detail !== "" ? closeDetail() : closePanel();
    }

    // Close the panel or launcher if its monitor gets unplugged.
    Connections {
        target: Quickshell

        function onScreensChanged(): void {
            // Clearing the screen also unmaps the window right away, so it
            // doesn't reappear on another output for the close animation.
            if (root.panelScreen && !Quickshell.screens.includes(root.panelScreen)) {
                root.closePanel();
                root.panelScreen = null;
            }
            if (root.launcherScreen && !Quickshell.screens.includes(root.launcherScreen)) {
                root.closeLauncher();
                root.launcherScreen = null;
            }
        }
    }
}
