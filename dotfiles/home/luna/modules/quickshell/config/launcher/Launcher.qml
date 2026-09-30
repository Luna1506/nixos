import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// Full-screen transparent overlay on the focused monitor while the launcher
// is open: the card fades and scales in at the center, a click anywhere
// else closes it.
PanelWindow {
    id: root

    // 0 = closed, 1 = open. The window stays mapped until the close animation
    // has finished; hotkey spam just retargets the animation.
    property real progress: ShellState.launcherOpen ? 1 : 0

    Behavior on progress {
        Anim {
            easing.bezierCurve: Theme.anim.emphasizedDecel
        }
    }

    visible: ShellState.launcherScreen !== null && (ShellState.launcherOpen || progress > 0)
    screen: ShellState.launcherScreen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    // Exclusive while open so typing goes straight into the search field;
    // released immediately on close so the previous window gets its focus
    // back.
    WlrLayershell.keyboardFocus: ShellState.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Click-through while the close animation is still running.
    mask: Region {
        item: ShellState.launcherOpen ? scope : null
    }

    Connections {
        target: ShellState

        function onLauncherOpenChanged(): void {
            if (!ShellState.launcherOpen)
                return;
            Apps.prepare();
            ClaudeUsage.refreshIfStale();
            content.reset();
        }
    }

    FocusScope {
        id: scope

        anchors.fill: parent
        focus: true

        // Click outside the launcher.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: ShellState.closeLauncher()
        }

        LauncherContent {
            id: content

            anchors.centerIn: parent
            width: Math.min(Theme.size.launcherWidth, parent.width - 2 * Theme.size.screenMargin)
            height: Math.round(parent.height * Theme.size.launcherMaxHeightShare)
            opacity: root.progress
            scale: Theme.anim.popInScale + (1 - Theme.anim.popInScale) * root.progress
        }
    }
}
