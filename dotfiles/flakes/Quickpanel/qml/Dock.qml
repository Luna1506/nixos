// ─── Dock.qml ─────────────────────────────────────────────────────────────────
// macOS-style floating dock for Hyprland.
//
// Behaviour
// ─────────
//   • Appears (slides up from bottom) only when the active workspace is EMPTY.
//   • Lists every mapped, non-floating window from ALL workspaces.
//   • Clicking a DockItem focuses that window and jumps to its workspace.
//
// Dependencies: Quickshell.Hyprland (reactive IPC), no polling needed.
//
// API note – Quickshell.Hyprland (≥ 0.2)
// ──────────────────────────────────────
//   Hyprland.clients         → array of HyprlandClient
//   Hyprland.activeWorkspace → HyprlandWorkspace | null
//   Hyprland.dispatch(cmd)   → send a hyprctl dispatcher command
//   HyprlandClient:
//     .address, .title, .class_, .floating, .mapped, .hidden
//     .workspace.id, .workspace.name

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    // ── Colour palette (matches QuickPanel purple theme) ─────────────────────
    readonly property color cBase:    "#0d0d1a"
    readonly property color cSurface: "#1a0a2e"
    readonly property color cOverlay: "#2a1a4a"
    readonly property color cText:    "#D19CFF"
    readonly property color cSubtext: "#8a6aaa"
    readonly property color cAccent:  "#a855f7"
    readonly property color cGreen:   "#a855f7"

    // ── Sizing constants ──────────────────────────────────────────────────────
    readonly property int iconBase:    52
    readonly property int iconHover:   70
    readonly property int dockHeight:  80
    readonly property int dockPad:     14
    readonly property int dockGap:     10
    readonly property int dockMarginB: 14

    // ── State ─────────────────────────────────────────────────────────────────
    property var  visibleClients: []
    property bool emptyWorkspace: false

    // ── Layer-shell ───────────────────────────────────────────────────────────
    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only anchor bottom → compositor centres the window horizontally
    anchors.bottom: true
    exclusiveZone:  0

    implicitWidth:  Math.max(pill.implicitWidth, 120)
    implicitHeight: dockHeight + dockMarginB + 16

    color: "transparent"

    // ── Helper: recompute state ───────────────────────────────────────────────
    function refresh() {
        var ws = Hyprland.activeWorkspace
        if (!ws) {
            emptyWorkspace = false
            visibleClients = []
            return
        }

        var all = Hyprland.clients.filter(function(c) {
            return c.mapped && !c.floating && !c.hidden
        })
        visibleClients = all

        var onActive = all.filter(function(c) {
            return c.workspace && c.workspace.id === ws.id
        })
        emptyWorkspace = (onActive.length === 0)
    }

    // ── React to Hyprland events ──────────────────────────────────────────────
    Connections {
        target: Hyprland
        function onClientsChanged()         { root.refresh() }
        function onActiveWorkspaceChanged() { root.refresh() }
        function onWorkspacesChanged()      { root.refresh() }
    }

    Component.onCompleted: refresh()

    // ── Animated visibility ───────────────────────────────────────────────────
    // Always visible=true; content slides off-screen when emptyWorkspace=false.
    visible: true

    Item {
        id: dockRoot
        anchors.fill: parent

        y: root.emptyWorkspace ? 0 : (root.dockHeight + root.dockMarginB + 32)

        Behavior on y {
            SpringAnimation { spring: 5.5; damping: 0.72; epsilon: 0.5 }
        }

        opacity: root.emptyWorkspace ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        // ── Blurred pill ──────────────────────────────────────────────────────
        Rectangle {
            id: pill
            anchors {
                bottom:           parent.bottom
                bottomMargin:     root.dockMarginB
                horizontalCenter: parent.horizontalCenter
            }

            implicitWidth:  iconRow.implicitWidth + root.dockPad * 2
            implicitHeight: root.dockHeight
            radius:         root.dockHeight / 2

            color:        Qt.rgba(0.05, 0.04, 0.10, 0.82)
            border.color: "#A015FE"
            border.width: 1

            // ── Icon row ──────────────────────────────────────────────────────
            RowLayout {
                id: iconRow
                anchors {
                    verticalCenter: parent.verticalCenter
                    left:           parent.left
                    right:          parent.right
                    leftMargin:     root.dockPad
                    rightMargin:    root.dockPad
                }
                spacing: root.dockGap

                Repeater {
                    model: root.visibleClients

                    DockItem {
                        required property var modelData
                        required property int index

                        panel:    root
                        client:   modelData
                        isActive: {
                            var ws = Hyprland.activeWorkspace
                            return ws && modelData.workspace &&
                                   modelData.workspace.id === ws.id
                        }

                        onFocusRequested: function(address) {
                            Hyprland.dispatch("focuswindow address:" + address)
                        }
                    }
                }
            }
        }
    }
}
