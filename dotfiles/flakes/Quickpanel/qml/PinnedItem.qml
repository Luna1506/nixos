// ─── PinnedItem.qml ───────────────────────────────────────────────────────────
// Dock icon for a statically pinned application.
//
// Features
// ────────
//   • Icon from system icon theme  (image://theme/<classname>)
//     Falls back to coloured circle with first letter.
//   • macOS-style spring magnification on hover.
//   • Tooltip: app name, shown above the icon.
//   • Active indicator dot when the app is running.
//   • Click → focus if running, launch if not.

import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland

Item {
    id: root

    // ── Required inputs ───────────────────────────────────────────────────────
    required property var  panel      // Dock root (colours + size constants)
    required property var  pinnedApp  // { name, class, exec }

    // ── Running state ─────────────────────────────────────────────────────────
    readonly property bool isRunning: {
        var tls = Hyprland.toplevels.values
        var cls = pinnedApp.class.toLowerCase()
        for (var i = 0; i < tls.length; i++) {
            var tc = (tls[i].lastIpcObject.class ?? "").toLowerCase()
            if (tc === cls) return true
        }
        return false
    }

    // ── Sizing ────────────────────────────────────────────────────────────────
    implicitWidth:  panel.iconHover + 4
    implicitHeight: panel.dockHeight

    // ── Hover ─────────────────────────────────────────────────────────────────
    property bool hovered: false

    readonly property real targetScale: hovered
        ? (panel.iconHover / panel.iconBase)
        : 1.0

    // ── Tooltip ───────────────────────────────────────────────────────────────
    Rectangle {
        id: tooltip
        z: 100
        visible: root.hovered
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        x: (parent.width - width) / 2

        property real scaledIconHalfH: (panel.iconBase / 2) * iconRect.scale
        property real iconCentreY:     parent.height / 2 - 5
        y: iconCentreY - scaledIconHalfH - height - 8

        implicitWidth:  Math.min(ttLabel.implicitWidth + 20, 210)
        implicitHeight: ttLabel.implicitHeight + 10
        radius:         8

        color:        Qt.rgba(0.10, 0.06, 0.18, 0.92)
        border.color: Qt.rgba(0.627, 0.082, 0.996, 0.35)
        border.width: 1

        Text {
            id: ttLabel
            anchors.centerIn: parent
            text:             root.pinnedApp.name
            color:            panel.cText
            font.pixelSize:   11
            font.weight:      Font.Medium
            elide:            Text.ElideRight
            width:            Math.min(implicitWidth, 190)
        }
    }

    // ── Icon rectangle ────────────────────────────────────────────────────────
    Rectangle {
        id: iconRect
        width:  panel.iconBase
        height: panel.iconBase
        radius: panel.iconBase * 0.22

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter:   parent.verticalCenter
            verticalCenterOffset: -5
        }

        color:        iconFallback.visible ? root.iconColor() : "transparent"
        border.color: Qt.rgba(1, 1, 1, iconFallback.visible ? 0.08 : 0.0)
        border.width: 1

        scale: root.targetScale
        Behavior on scale {
            SpringAnimation { spring: 7.0; damping: 0.55; epsilon: 0.005 }
        }

        SequentialAnimation {
            id: bounceAnim
            alwaysRunToEnd: true
            PropertyAnimation {
                target: iconRect; property: "scale"
                to: root.targetScale * 0.80
                duration: 75; easing.type: Easing.InCubic
            }
            PropertyAnimation {
                target: iconRect; property: "scale"
                to: root.targetScale * 1.10
                duration: 130; easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: iconRect; property: "scale"
                to: root.targetScale
                duration: 200; easing.type: Easing.OutElastic
            }
        }

        // ── System icon ───────────────────────────────────────────────────────
        Image {
            id: iconImage
            anchors.fill:    parent
            anchors.margins: 4
            source: {
                var name = root.pinnedApp.icon || root.pinnedApp.class || ""
                if (!name) return ""
                var p = Quickshell.iconPath(name, "")
                if (!p) p = Quickshell.iconPath(name.toLowerCase(), "")
                return p ? ("file://" + p) : ""
            }
            fillMode:        Image.PreserveAspectFit
            smooth:          true
            mipmap:          true
            visible:         status === Image.Ready
        }

        // ── Letter fallback ───────────────────────────────────────────────────
        Item {
            id: iconFallback
            anchors.fill: parent
            visible:      iconImage.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text:       (root.pinnedApp.class || "?").charAt(0).toUpperCase()
                font.pixelSize: parent.width * 0.42
                font.weight:    Font.Bold
                color:          "#ffffff"
            }
        }

        // ── Hover outline ─────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius:       parent.radius
            color:        "transparent"
            border.color: root.hovered ? Qt.rgba(0.627, 0.082, 0.996, 0.60) : "transparent"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 100 } }
        }
    }

    // ── Active dot ────────────────────────────────────────────────────────────
    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom:           parent.bottom
            bottomMargin:     8
        }
        width: 6; height: 6; radius: 3

        color:   root.isRunning ? panel.cAccent : Qt.rgba(0.659, 0.333, 0.969, 0.30)
        opacity: root.isRunning ? 1.0 : 0.40

        Behavior on color   { ColorAnimation  { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited:  root.hovered = false

        onClicked: {
            bounceAnim.restart()
            if (root.isRunning) {
                Hyprland.dispatch("focuswindow class:" + root.pinnedApp.class)
            } else {
                Hyprland.dispatch("exec " + root.pinnedApp.exec)
            }
        }
    }

    // ── Deterministic colour from class name ──────────────────────────────────
    function iconColor() {
        var cls  = root.pinnedApp.class || "?"
        var hash = 0
        for (var i = 0; i < cls.length; i++)
            hash = (hash * 31 + cls.charCodeAt(i)) & 0xFFFFFF

        var h = (hash        & 0xFF) / 255
        var s = 0.50 + ((hash >> 8  & 0xFF) / 255) * 0.35
        var v = 0.52 + ((hash >> 16 & 0xFF) / 255) * 0.22
        return Qt.hsva(h, s, v, 1)
    }
}
