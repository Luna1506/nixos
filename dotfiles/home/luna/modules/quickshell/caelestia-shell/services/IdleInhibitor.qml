pragma Singleton

import Quickshell
import Quickshell.Io

// NOTE:
// Some Quickshell builds don't ship an IdleInhibitor QML type.
// This stub keeps the Caelestia API working so the shell can start.
// If you later confirm the correct type name/module for your Quickshell,
// you can re-enable the real inhibitor implementation.

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
