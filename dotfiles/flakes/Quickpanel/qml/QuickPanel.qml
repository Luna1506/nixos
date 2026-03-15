// ─── QuickPanel.qml ───────────────────────────────────────────────────────────
// Floating overlay panel – anchored to the top-right of the primary screen.
// Contains two tabs: Status (WiFi / BT / Battery / Clock) and Player.

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: root

    // ── Colours ───────────────────────────────────────────────────────────────
    readonly property color cBase:       "#0d0d1a"
    readonly property color cCard:       "#12122a"
    readonly property color cBorder:     "#2a1a4a"
    readonly property color cText:       "#D19CFF"
    readonly property color cSubtext:    "#8a6aaa"
    readonly property color cNeonCyan:   "#a855f7"
    readonly property color cNeonPink:   "#ec4899"
    readonly property color cNeonViolet: "#7c3aed"
    readonly property color cNeonYellow: "#c084fc"

    // ── Layer-shell setup ─────────────────────────────────────────────────────
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top:   true
        right: true
    }
    exclusiveZone: -1

    margins {
        top:   52
        right: 14
    }

    // ── Size – fixed height so content scrolls inside ─────────────────────────
    implicitWidth:  560
    implicitHeight: 620

    Keys.onEscapePressed: root.visible = false

    // ── Background ────────────────────────────────────────────────────────────
    color: "transparent"

    // Dark base
    Rectangle {
        anchors.fill: parent
        color:        root.cBase
        radius:       16
    }

    // Radial gradient – top-left: lila/violet
    RadialGradient {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.627, 0.082, 0.996, 0.22) }  // #A015FE
            GradientStop { position: 1.0; color: "transparent" }
        }
        horizontalOffset: -parent.width  * 0.3
        verticalOffset:   -parent.height * 0.3
        horizontalRadius:  parent.width  * 0.75
        verticalRadius:    parent.height * 0.55
    }

    // Radial gradient – bottom-right: cyan/pink
    RadialGradient {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.933, 0.286, 0.6, 0.16) }   // pink
            GradientStop { position: 1.0; color: "transparent" }
        }
        horizontalOffset:  parent.width  * 0.35
        verticalOffset:    parent.height * 0.35
        horizontalRadius:  parent.width  * 0.65
        verticalRadius:    parent.height * 0.5
    }

    // Border overlay (rounded rect on top of gradient)
    Rectangle {
        anchors.fill: parent
        color:        "transparent"
        radius:       16
        border.color: "#A015FE"
        border.width: 1
    }

    // ── Content ───────────────────────────────────────────────────────────────
    ColumnLayout {
        id: outerCol
        anchors {
            top:         parent.top
            left:        parent.left
            right:       parent.right
            bottom:      parent.bottom
            topMargin:   14
            leftMargin:  14
            rightMargin: 14
            bottomMargin: 14
        }
        spacing: 0

        // ── Tab Toggle Bar ────────────────────────────────────────────────────
        Item {
            id: tabToggle
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            implicitHeight: 36

            property int currentIndex: 0

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

                Rectangle {
                    width:  tabToggle.width / 2
                    height: tabToggle.implicitHeight
                    color:  "transparent"

                    Text {
                        anchors.centerIn: parent
                        text:           "  Status"
                        font.pixelSize: 13
                        font.weight:    Font.Medium
                        color: tabToggle.currentIndex === 0 ? root.cNeonCyan : root.cSubtext
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: tabToggle.currentIndex = 0
                    }
                }

                Rectangle {
                    width:  tabToggle.width / 2
                    height: tabToggle.implicitHeight
                    color:  "transparent"

                    Text {
                        anchors.centerIn: parent
                        text:           "  Player"
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

        // ── Scrollable Tab Content ────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip:              true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy:   ScrollBar.AsNeeded

            // Style the vertical scrollbar
            ScrollBar.vertical: ScrollBar {
                width: 6
                contentItem: Rectangle {
                    implicitWidth:  6
                    implicitHeight: 50
                    radius:         3
                    color:          Qt.rgba(0.659, 0.333, 0.969, 0.5)
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            StackLayout {
                width:        parent.width
                currentIndex: tabToggle.currentIndex

                StatusTab {
                    panel: root
                }

                PlayerTab {
                    panel: root
                }
            }
        }
    }
}
