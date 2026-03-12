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

    // ── Colour palette (matches quickpanel / hyprfrost) ───────────────────────
    readonly property color cBase:    "#1e1e2e"
    readonly property color cSurface: "#313244"
    readonly property color cOverlay: "#45475a"
    readonly property color cText:    "#cdd6f4"
    readonly property color cSubtext: "#a6adc8"
    readonly property color cAccent:  "#89b4fa"
    readonly property color cGreen:   "#a6e3a1"

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
    WlrLayerShell.layer:         WlrLayerShell.Layer.Top
    WlrLayerShell.keyboardFocus: WlrLayerShell.KeyboardFocus.None

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

        // ── Frosted-glass pill ────────────────────────────────────────────────
        Rectangle {
            id: pill
            anchors {
                bottom:           parent.bottom
                bottomMargin:     root.dockMarginB
                horizontalCenter: parent.horizontalCenter
            }

            // dockPad left + dockPad right (row is anchored with leftMargin only)
            implicitWidth:  iconRow.implicitWidth + root.dockPad * 2
            implicitHeight: root.dockHeight
            radius:         root.dockHeight / 2   // full pill

            // Same frosted-glass recipe as hyprfrost / quickpanel
            color:        Qt.rgba(0.12, 0.12, 0.18, 0.72)
            border.color: Qt.rgba(1, 1, 1, 0.13)
            border.width: 1

            // Specular top edge
            Rectangle {
                anchors {
                    top:         parent.top
                    left:        parent.left
                    right:       parent.right
                    topMargin:   1
                    leftMargin:  root.dockHeight / 2
                    rightMargin: root.dockHeight / 2
                }
                height: 1
                color:  Qt.rgba(1, 1, 1, 0.18)
                radius: 1
            }

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

            // Bottom shadow line
            Rectangle {
                anchors {
                    bottom:       parent.bottom
                    left:         parent.left
                    right:        parent.right
                    bottomMargin: 1
                    leftMargin:   root.dockHeight / 2
                    rightMargin:  root.dockHeight / 2
                }
                height: 1
                color:  Qt.rgba(0, 0, 0, 0.25)
                radius: 1
            }
        }
    }
}
