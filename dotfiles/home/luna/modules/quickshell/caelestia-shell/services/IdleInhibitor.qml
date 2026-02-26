pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland as QW

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    onEnabledChanged: {
        if (enabled)
            props.enabledSince = new Date();
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    QW.IdleInhibitor {
        enabled: props.enabled

        // Minimal window, kein Region/Mask, damit es nicht an fehlenden Typen scheitert
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            visible: false
            color: "transparent"
        }
    }

    IpcHandler {
        target: "idleInhibitor"

        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }
    }
}
