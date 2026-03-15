// ─── AppMenuButton.qml ────────────────────────────────────────────────────────
// 9-dot grid button that toggles the AppLauncher via QS IPC.

import Quickshell
import QtQuick

Item {
    id: root

    required property var panel  // Dock root (colours + size constants)

    implicitWidth:  panel.iconBase + 4
    implicitHeight: panel.dockHeight

    property bool hovered: false

    // ── Icon ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: btnRect
        width:  panel.iconBase
        height: panel.iconBase
        radius: panel.iconBase * 0.22

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter:   parent.verticalCenter
            verticalCenterOffset: -5
        }

        color:        Qt.rgba(0.05, 0.04, 0.10, 0.60)
        border.color: root.hovered
            ? Qt.rgba(0.627, 0.082, 0.996, 0.60)
            : Qt.rgba(0.627, 0.082, 0.996, 0.20)
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 100 } }

        scale: root.hovered ? (panel.iconHover / panel.iconBase) : 1.0
        Behavior on scale {
            SpringAnimation { spring: 7.0; damping: 0.55; epsilon: 0.005 }
        }

        Image {
            anchors.centerIn: parent
            width:  parent.width  * 0.58
            height: parent.height * 0.58
            source: Qt.resolvedUrl("icons/appmenu.svg")
            fillMode: Image.PreserveAspectFit
            smooth:   true
            mipmap:   true
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "applaunch", "toggle"])
    }
}
