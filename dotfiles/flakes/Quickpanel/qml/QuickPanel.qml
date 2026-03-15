// ─── QuickPanel.qml ───────────────────────────────────────────────────────────
// Floating overlay panel – anchored to the top-right of the primary screen.
// Contains two tabs: Status (WiFi / BT / Battery / Clock) and Player.

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: root

    // ── Colours ───────────────────────────────────────────────────────────────
    readonly property color cBase:    "#1e1e2e"
    readonly property color cSurface: "#313244"
    readonly property color cOverlay: "#45475a"
    readonly property color cText:    "#cdd6f4"
    readonly property color cSubtext: "#a6adc8"
    readonly property color cAccent:  "#89b4fa"
    readonly property color cGreen:   "#a6e3a1"
    readonly property color cRed:     "#f38ba8"
    readonly property color cYellow:  "#f9e2af"

    // ── Layer-shell setup ─────────────────────────────────────────────────────
    // Overlay layer → appears above all normal windows.
    layer:         WlrLayerShell.Layer.Overlay
    keyboardFocus: WlrLayerShell.KeyboardFocus.OnDemand

    // Anchor to top-right; no exclusive zone (doesn't push other windows).
    anchors {
        top:   true
        right: true
    }
    exclusiveZone: -1

    margins {
        top:   52    // below a typical top bar
        right: 12
    }

    // ── Size ──────────────────────────────────────────────────────────────────
    implicitWidth:  360
    implicitHeight: contentCol.implicitHeight + 24   // 12px top + 12px bottom

    // ── Close on Escape ───────────────────────────────────────────────────────
    Keys.onEscapePressed: root.visible = false

    // ── Background ────────────────────────────────────────────────────────────
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color:        root.cBase
        radius:       14
        border.color: root.cOverlay
        border.width: 1

        // Drop shadow via a second rectangle behind
        layer.enabled: true
        layer.effect: null   // replace with MultiEffect if available
    }

    // ── Content ───────────────────────────────────────────────────────────────
    ColumnLayout {
        id: contentCol
        anchors {
            top:    parent.top
            left:   parent.left
            right:  parent.right
            topMargin:    12
            leftMargin:   12
            rightMargin:  12
        }
        spacing: 0

        // ── Tab bar ───────────────────────────────────────────────────────────
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.bottomMargin: 10

            background: Rectangle {
                color:  root.cSurface
                radius: 8
            }

            TabButton {
                text: "  Status"
                width: implicitWidth

                contentItem: Text {
                    text:           parent.text
                    color:          tabBar.currentIndex === 0
                                        ? root.cAccent : root.cSubtext
                    font.pixelSize: 13
                    font.weight:    Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    color:  tabBar.currentIndex === 0 ? root.cOverlay : "transparent"
                    radius: 6
                }
            }

            TabButton {
                text: "  Player"
                width: implicitWidth

                contentItem: Text {
                    text:           parent.text
                    color:          tabBar.currentIndex === 1
                                        ? root.cAccent : root.cSubtext
                    font.pixelSize: 13
                    font.weight:    Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    color:  tabBar.currentIndex === 1 ? root.cOverlay : "transparent"
                    radius: 6
                }
            }
        }

        // ── Tab content ───────────────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true   // without this StackLayout collapses to 0
            currentIndex:      tabBar.currentIndex

            StatusTab {
                panel: root
            }

            PlayerTab {
                panel: root
            }
        }
    }
}
