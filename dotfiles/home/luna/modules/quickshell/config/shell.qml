//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.panel
import qs.notifications
import qs.osd

ShellRoot {
    // Singletons are created lazily; these must run from the start
    // (notification daemon, restoring the night light).
    Component.onCompleted: {
        Notifications.count;
        NightLight.enabled;
    }

    ControlCenter {}

    ClickCatcher {}

    NotificationPopups {}

    WorkspaceOsd {}

    // Hyprland: bind = SUPER, N, global, quickshell:panelToggle
    GlobalShortcut {
        name: "panelToggle"
        description: "Toggle the control center"
        onPressed: ShellState.togglePanel()
    }

    // qs -c luna ipc call panel toggle|open|close|detail <wifi|bluetooth|audio>
    IpcHandler {
        target: "panel"

        function toggle(): void {
            ShellState.togglePanel();
        }

        function open(): void {
            ShellState.openPanel();
        }

        function close(): void {
            ShellState.closePanel();
        }

        function detail(name: string): void {
            ShellState.openDetail(name);
        }
    }

    // qs -c luna ipc call toggle dnd|nightLight
    IpcHandler {
        target: "toggle"

        function dnd(): void {
            Notifications.toggleDnd();
        }

        function nightLight(): void {
            NightLight.toggle();
        }
    }
}
