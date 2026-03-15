// ─── AppLauncher.qml ──────────────────────────────────────────────────────────
// Centered floating app launcher with search + 3-column icon grid.

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: root

    // ── IPC toggle ────────────────────────────────────────────────────────────
    IpcHandler {
        target: "applaunch"
        function toggle(): void {
            root.visible = !root.visible
            if (root.visible) {
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
        function show(): void {
            root.visible = true
            searchField.text = ""
            searchField.forceActiveFocus()
        }
        function hide(): void { root.visible = false }
    }

    // ── Colours (matches QuickPanel) ──────────────────────────────────────────
    readonly property color cBase:    "#0d0d1a"
    readonly property color cText:    "#D19CFF"
    readonly property color cSubtext: "#8a6aaa"
    readonly property color cAccent:  "#a855f7"

    // ── Layer-shell ───────────────────────────────────────────────────────────
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors.left:   false
    anchors.right:  false
    anchors.top:    false
    anchors.bottom: false

    implicitWidth:  420
    implicitHeight: 580

    color:   "transparent"
    visible: false

    Keys.onEscapePressed: root.visible = false

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        root.cBase
        radius:       16
    }

    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var g1 = ctx.createRadialGradient(
                width * 0.05, height * 0.05, 0,
                width * 0.05, height * 0.05, width * 0.75
            )
            g1.addColorStop(0,   Qt.rgba(0.627, 0.082, 0.996, 0.30))
            g1.addColorStop(1.0, Qt.rgba(0, 0, 0, 0))
            ctx.fillStyle = g1
            ctx.fillRect(0, 0, width, height)

            var g2 = ctx.createRadialGradient(
                width * 0.95, height * 0.90, 0,
                width * 0.95, height * 0.90, width * 0.65
            )
            g2.addColorStop(0,   Qt.rgba(0.933, 0.286, 0.600, 0.22))
            g2.addColorStop(1.0, Qt.rgba(0, 0, 0, 0))
            ctx.fillStyle = g2
            ctx.fillRect(0, 0, width, height)
        }
    }

    Rectangle {
        anchors.fill: parent
        color:        "transparent"
        radius:       16
        border.color: "#A015FE"
        border.width: 1
    }

    // ── Search text ───────────────────────────────────────────────────────────
    property string searchText: ""

    // ── Content ───────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors {
            fill:        parent
            margins:     14
        }
        spacing: 10

        // ── Search bar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   40
            radius:           10
            color:            Qt.rgba(0.05, 0.04, 0.10, 0.80)
            border.color:     searchField.activeFocus
                              ? Qt.rgba(0.627, 0.082, 0.996, 0.80)
                              : Qt.rgba(0.627, 0.082, 0.996, 0.30)
            border.width:     1
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Row {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left:           parent.left
                    leftMargin:     10
                    right:          parent.right
                    rightMargin:    10
                }
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "🔍"
                    font.pixelSize: 14
                    color:          root.cSubtext
                }

                TextInput {
                    id:                   searchField
                    width:                parent.width - 30
                    anchors.verticalCenter: parent.verticalCenter
                    color:                root.cText
                    font.pixelSize:       14
                    font.weight:          Font.Medium
                    placeholderText:      "App suchen…"
                    placeholderTextColor: root.cSubtext
                    selectByMouse:        true
                    clip:                 true
                    onTextChanged:        root.searchText = text.toLowerCase()
                    Keys.onEscapePressed: root.visible = false
                }
            }
        }

        // ── App grid ──────────────────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip:              true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy:   ScrollBar.AsNeeded

            GridView {
                id:         grid
                width:      parent.width
                cellWidth:  Math.floor(width / 3)
                cellHeight: 110
                clip:       true

                model: DesktopEntries.applications

                delegate: AppLauncherItem {
                    required property var modelData

                    width:  grid.cellWidth
                    height: grid.cellHeight

                    entry: modelData

                    visible: {
                        if (modelData.noDisplay) return false
                        if (root.searchText === "") return true
                        var n = (modelData.name || "").toLowerCase()
                        var k = (modelData.keywords || "").toLowerCase()
                        return n.includes(root.searchText) || k.includes(root.searchText)
                    }

                    onLaunched: root.visible = false
                }
            }
        }
    }
}
