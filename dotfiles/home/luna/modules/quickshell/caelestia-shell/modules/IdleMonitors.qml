// ~/nixos/dotfiles/home/luna/modules/quickshell/caelestia-shell/modules/IdleMonitors.qml
pragma ComponentBehavior: Bound

import "lock"
import qs.config
import qs.services
import Caelestia.Internal
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    required property Lock lock

    // Keep the same "enabled" logic so other code can still bind to it.
    // NOTE: Idle timeouts are disabled on Quickshell 0.2.1 because IdleMonitor
    // is not available there.
    readonly property bool enabled: !Config.general.idle.inhibitWhenAudio || !Players.list.some(p => p.isPlaying)

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        if (action === "lock")
            lock.lock.locked = true;
        else if (action === "unlock")
            lock.lock.locked = false;
        else if (typeof action === "string")
            Hypr.dispatch(action);
        else
            Quickshell.execDetached(action);
    }

    LogindManager {
        onAboutToSleep: {
            if (Config.general.idle.lockBeforeSleep)
                root.lock.lock.locked = true;
        }
        onLockRequested: root.lock.lock.locked = true
        onUnlockRequested: root.lock.lock.unlock()
    }

    // Quickshell 0.2.1 compatibility:
    // IdleMonitor does not exist -> disable idle timeout handling for now.
    //
    // If you later upgrade Quickshell to a version that provides IdleMonitor,
    // you can restore the original Variants + IdleMonitor block here.
}
