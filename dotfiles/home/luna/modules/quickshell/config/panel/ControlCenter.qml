import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services
import qs.details

// Full-screen transparent overlay on the focused monitor while the panel is
// open: the panel slides in on the right, detail views slide out to its
// left, and a click anywhere else closes everything.
PanelWindow {
    id: root

    // 0 = closed, 1 = open. The window stays mapped until the close animation
    // has finished; hotkey spam just retargets the animation.
    property real progress: ShellState.panelOpen ? 1 : 0

    Behavior on progress {
        Anim {
            duration: Theme.anim.slow
            easing.bezierCurve: Theme.anim.emphasizedDecel
        }
    }

    visible: ShellState.panelScreen !== null && (ShellState.panelOpen || progress > 0)
    screen: ShellState.panelScreen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"
    // Exclusive while open (Escape, password input); released immediately
    // on close so the previous window gets its focus back.
    WlrLayershell.keyboardFocus: ShellState.panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Click-through while the close animation is still running.
    mask: Region {
        item: ShellState.panelOpen ? scope : null
    }

    Connections {
        target: ShellState

        function onPanelOpenChanged(): void {
            if (!ShellState.panelOpen)
                return;
            Brightness.refresh();
            Notifications.clearPopups();
            scope.forceActiveFocus();
        }

        function onDetailChanged(): void {
            scope.forceActiveFocus();
        }
    }

    FocusScope {
        id: scope

        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.back()

        // Click outside the panel.
        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closePanel()
        }

        Item {
            id: slider

            anchors.fill: parent
            // Reaches full opacity before the slide ends.
            opacity: Math.min(1, root.progress * Theme.anim.fadeLead)

            transform: Translate {
                x: (1 - root.progress) * (panel.width + Theme.size.screenMargin)
            }

            Panel {
                id: panel

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: Theme.size.screenMargin
                width: Theme.size.panelWidth
            }

            DetailHost {
                anchors.top: panel.top
                anchors.right: panel.left
                anchors.rightMargin: Theme.spacing.md
                maxHeight: panel.height
            }
        }
    }
}
