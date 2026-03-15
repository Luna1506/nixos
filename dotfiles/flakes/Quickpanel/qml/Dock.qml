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
    readonly property int tooltipOverhead: 44

    // ── Pinned apps ───────────────────────────────────────────────────────────
    readonly property var pinnedApps: [
        { name: "Ghostty",     "class": "com.mitchellh.ghostty", icon: "com.mitchellh.ghostty", exec: "ghostty" },
        { name: "Zen Browser", "class": "zen",                   icon: "zen-browser",           exec: "zen" },
        { name: "Vesktop",     "class": "vesktop",               icon: "vesktop",               exec: "vesktop" },
        { name: "Spotify",     "class": "spotify",               icon: "spotify",               exec: "spotify" },
        { name: "Steam",       "class": "steam",                 icon: "steam",                 exec: "steam" },
    ]

    readonly property int openWindowCount: {
        var count = 0
        var tls = Hyprland.toplevels.values
        for (var i = 0; i < tls.length; i++)
            if (!tls[i].lastIpcObject.floating) count++
        return count
    }

    // ── State ─────────────────────────────────────────────────────────────────
    property bool emptyWorkspace: false

    function refreshEmpty() {
        var ws = Hyprland.focusedWorkspace
        emptyWorkspace = ws ? ws.toplevels.values.length === 0 : false
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.refreshEmpty() }
        function onToplevelsChanged()        { root.refreshEmpty() }
    }

    Connections {
        target: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.toplevels : null
        function onValuesChanged() { root.refreshEmpty() }
    }

    Component.onCompleted: refreshEmpty()

    // ── Layer-shell ───────────────────────────────────────────────────────────
    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only anchor bottom → compositor centres the window horizontally
    anchors.bottom: true
    exclusiveZone:  0

    implicitWidth:  Math.max(pill.implicitWidth, 120)
    implicitHeight: dockHeight + dockMarginB + 16 + tooltipOverhead

    color: "transparent"
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

                // ── Pinned apps ───────────────────────────────────────────────
                Repeater {
                    model: root.pinnedApps

                    PinnedItem {
                        required property var modelData

                        panel:      root
                        pinnedApp:  modelData
                    }
                }

                // ── Separator ─────────────────────────────────────────────────
                Rectangle {
                    visible:          root.openWindowCount > 0
                    width:            1
                    height:           root.iconBase * 0.75
                    color:            Qt.rgba(0.627, 0.082, 0.996, 0.35)
                    Layout.alignment: Qt.AlignVCenter
                }

                // ── Open windows ──────────────────────────────────────────────
                Repeater {
                    model: Hyprland.toplevels.values

                    DockItem {
                        required property var modelData
                        required property int index

                        panel:    root
                        client:   modelData
                        isActive: modelData.activated

                        onFocusRequested: function(address) {
                            Hyprland.dispatch("focuswindow address:" + address)
                        }
                    }
                }

                // ── App menu button ───────────────────────────────────────────
                AppMenuButton {
                    panel: root
                }
            }
        }
    }
}
