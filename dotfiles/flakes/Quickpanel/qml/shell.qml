// ─── shell.qml ────────────────────────────────────────────────────────────────
// Quickshell entry point – lädt StatusPanel + Dock.
//
// Keybinds (in hyprland.conf eintragen):
//   bind = SUPER, P, exec, qs ipc call quickpanel toggle
//
// Der Dock erscheint automatisch auf leeren Workspaces – kein Keybind nötig.

import Quickshell
import Quickshell.Io

ShellRoot {

    // ── IPC: Status-/Mediapanel per Shortcut toggeln ──────────────────────────
    IpcHandler {
        target: "quickpanel"

        function toggle(): void {
            panel.visible = !panel.visible
        }

        function show(): void  { panel.visible = true  }
        function hide(): void  { panel.visible = false }
    }

    // ── Status / Media Panel  (SUPER + P) ─────────────────────────────────────
    QuickPanel { id: panel }

    // ── macOS-Dock (erscheint automatisch auf leeren Workspaces) ─────────────
    Dock {}
}
