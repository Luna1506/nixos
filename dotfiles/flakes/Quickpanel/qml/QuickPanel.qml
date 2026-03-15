// ─── QuickPanel.qml ───────────────────────────────────────────────────────────
// Floating overlay panel – anchored to the top-right of the primary screen.
// Contains two tabs: Status (WiFi / BT / Battery / Clock) and Player.

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    // ── Colours ───────────────────────────────────────────────────────────────
    readonly property color cBase:       "#0a0a12"
    readonly property color cCard:       "#11111f"
    readonly property color cBorder:     "#1e1e3a"
    readonly property color cText:       "#e8e8ff"
    readonly property color cSubtext:    "#7070a0"
    readonly property color cNeonCyan:   "#00f5ff"
    readonly property color cNeonPink:   "#ff2d78"
    readonly property color cNeonViolet: "#bf00ff"
    readonly property color cNeonYellow: "#ffe600"

    // ── Layer-shell setup ─────────────────────────────────────────────────────
    // Overlay layer → appears above all normal windows.
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Anchor to top-right; no exclusive zone (doesn't push other windows).
    anchors {
        top:   true
        right: true
    }
    exclusiveZone: -1

    margins {
        top:   52
        right: 14
    }

    // ── Size ──────────────────────────────────────────────────────────────────
    implicitWidth:  560
    implicitHeight: contentCol.implicitHeight + 28

    // ── Close on Escape ───────────────────────────────────────────────────────
    Keys.onEscapePressed: root.visible = false

    // ── Background ────────────────────────────────────────────────────────────
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color:        root.cBase
        radius:       16
        border.color: root.cBorder
        border.width: 1
    }

    // ── Content ───────────────────────────────────────────────────────────────
    ColumnLayout {
        id: contentCol
        anchors {
            top:    parent.top
            left:   parent.left
            right:  parent.right
            topMargin:    14
            leftMargin:   14
            rightMargin:  14
        }
        spacing: 0

        // ── Custom Tab Toggle Bar ─────────────────────────────────────────────────
        Item {
            id: tabToggle
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            implicitHeight: 36

            property int currentIndex: 0

            // Animated neon underline indicator
            Rectangle {
                id: tabIndicator
                width:  tabToggle.width / 2
                height: 3
                radius: 1.5
                color:  root.cNeonCyan
                anchors.bottom: parent.bottom

                x: tabToggle.currentIndex * (tabToggle.width / 2)
                Behavior on x {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }

            Row {
                anchors.fill: parent

                // Status tab button
                Rectangle {
                    width:  tabToggle.width / 2
                    height: tabToggle.implicitHeight
                    color:  "transparent"

                    Text {
                        anchors.centerIn: parent
                        text:  "  Status"
                        font.pixelSize: 13
                        font.weight:    Font.Medium
                        color: tabToggle.currentIndex === 0 ? root.cNeonCyan : root.cSubtext
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: tabToggle.currentIndex = 0
                    }
                }

                // Player tab button
                Rectangle {
                    width:  tabToggle.width / 2
                    height: tabToggle.implicitHeight
                    color:  "transparent"

                    Text {
                        anchors.centerIn: parent
                        text:  "  Player"
                        font.pixelSize: 13
                        font.weight:    Font.Medium
                        color: tabToggle.currentIndex === 1 ? root.cNeonCyan : root.cSubtext
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: tabToggle.currentIndex = 1
                    }
                }
            }
        }

        // ── Tab content ───────────────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true   // without this StackLayout collapses to 0
            currentIndex:      tabToggle.currentIndex

            StatusTab {
                panel: root
            }

            PlayerTab {
                panel: root
            }
        }
    }
}
