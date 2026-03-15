// ─── AppLauncherItem.qml ──────────────────────────────────────────────────────
// Single app cell in the AppLauncher grid.

import Quickshell
import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property var entry    // DesktopEntry
    signal launched()

    implicitWidth:  120
    implicitHeight: 110

    property bool hovered: false

    // ── Icon rectangle ────────────────────────────────────────────────────────
    Rectangle {
        id: iconRect
        width:  52
        height: 52
        radius: 52 * 0.22

        anchors {
            horizontalCenter: parent.horizontalCenter
            top:              parent.top
            topMargin:        12
        }

        color:        iconImg.status === Image.Ready ? "transparent" : root.fallbackColor()
        border.color: root.hovered ? Qt.rgba(0.627, 0.082, 0.996, 0.60) : "transparent"
        border.width: 1

        scale: root.hovered ? 1.12 : 1.0
        Behavior on scale {
            SpringAnimation { spring: 7.0; damping: 0.55; epsilon: 0.005 }
        }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Image {
            id: iconImg
            anchors.fill:    parent
            anchors.margins: 4
            source:          Quickshell.iconPath(root.entry.icon || "", "")
            fillMode:        Image.PreserveAspectFit
            smooth:          true
            mipmap:          true
            visible:         status === Image.Ready
        }

        // Letter fallback
        Text {
            anchors.centerIn: parent
            visible:          iconImg.status !== Image.Ready
            text:             (root.entry.name || "?").charAt(0).toUpperCase()
            font.pixelSize:   22
            font.weight:      Font.Bold
            color:            "#ffffff"
        }
    }

    // ── App name ──────────────────────────────────────────────────────────────
    Text {
        anchors {
            top:              iconRect.bottom
            topMargin:        6
            horizontalCenter: parent.horizontalCenter
            left:             parent.left
            right:            parent.right
            leftMargin:       4
            rightMargin:      4
        }
        text:                root.entry.name || ""
        color:               root.hovered ? "#D19CFF" : "#8a6aaa"
        font.pixelSize:      11
        font.weight:         Font.Medium
        horizontalAlignment: Text.AlignHCenter
        elide:               Text.ElideRight
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    // ── Hover background ──────────────────────────────────────────────────────
    Rectangle {
        anchors.fill:    parent
        anchors.margins: 4
        radius:          10
        color:           root.hovered ? Qt.rgba(0.627, 0.082, 0.996, 0.10) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
        z:               -1
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered:    root.hovered = true
        onExited:     root.hovered = false
        onClicked: {
            root.entry.execute()
            root.launched()
        }
    }

    // ── Deterministic fallback colour from name ───────────────────────────────
    function fallbackColor() {
        var s    = root.entry.name || "?"
        var hash = 0
        for (var i = 0; i < s.length; i++)
            hash = (hash * 31 + s.charCodeAt(i)) & 0xFFFFFF
        var h   = (hash & 0xFF) / 255
        var sat = 0.50 + ((hash >> 8 & 0xFF) / 255) * 0.35
        var v   = 0.52 + ((hash >> 16 & 0xFF) / 255) * 0.22
        return Qt.hsva(h, sat, v, 1)
    }
}
