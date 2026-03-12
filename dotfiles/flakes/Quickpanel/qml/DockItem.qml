// ─── DockItem.qml ─────────────────────────────────────────────────────────────
// Single app window icon in the dock.
//
// Features
// ────────
//   • Icon from the system icon theme  (image://theme/<class>)
//     Falls back to a coloured circle with the first letter of the class name.
//   • macOS-style spring magnification on hover.
//   • Tooltip: window title, shown above the icon.
//   • Active indicator dot (green) when the window is on the current workspace.
//   • Workspace number badge (top-right) for windows on other workspaces.
//   • Click → emits focusRequested(address); bounce animation as tactile ack.

import QtQuick
import QtQuick.Controls

Item {
    id: root

    // ── Required inputs ───────────────────────────────────────────────────────
    required property var  panel     // Dock root (colours + size constants)
    required property var  client    // HyprlandClient
    required property bool isActive  // window is on the active workspace

    signal focusRequested(string address)

    // ── Sizing ────────────────────────────────────────────────────────────────
    // Reserve the hover size at all times so neighbours don't shift.
    implicitWidth:  panel.iconHover + 4
    implicitHeight: panel.dockHeight

    // ── Hover ─────────────────────────────────────────────────────────────────
    property bool hovered: false

    readonly property real targetScale: hovered
        ? (panel.iconHover / panel.iconBase)
        : 1.0

    // ── Tooltip ───────────────────────────────────────────────────────────────
    // Positioned using the SCALED height of the icon so it sits above the
    // magnified icon, not the original unscaled geometry.
    Rectangle {
        id: tooltip
        visible: root.hovered && root.client.title.length > 0
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        // Centre over the icon column
        x: (parent.width - width) / 2

        // Sit above the scaled icon:
        //   iconRect's centre is at parent.height/2 - 5 (verticalCenterOffset)
        //   scaled half-height = (panel.iconBase / 2) * iconRect.scale
        property real scaledIconHalfH: (panel.iconBase / 2) * iconRect.scale
        property real iconCentreY:     parent.height / 2 - 5
        y: iconCentreY - scaledIconHalfH - height - 8

        implicitWidth:  Math.min(ttLabel.implicitWidth + 20, 210)
        implicitHeight: ttLabel.implicitHeight + 10
        radius:         8

        color:        panel.cSurface
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        Text {
            id: ttLabel
            anchors.centerIn: parent
            text:             root.client.title
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
        radius: panel.iconBase * 0.22   // macOS rounded-square

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter:   parent.verticalCenter
            verticalCenterOffset: -5    // shift up to leave room for the dot
        }

        // Background only visible when the icon image fails to load
        color:        iconFallback.visible ? root.iconColor() : "transparent"
        border.color: Qt.rgba(1, 1, 1, iconFallback.visible ? 0.08 : 0.0)
        border.width: 1

        // Spring scale
        scale: root.targetScale
        Behavior on scale {
            SpringAnimation { spring: 7.0; damping: 0.55; epsilon: 0.005 }
        }

        // Bounce on click
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
            source:          "image://theme/" + (root.client.class_ || "application-x-executable")
            fillMode:        Image.PreserveAspectFit
            smooth:          true
            mipmap:          true
            visible:         status === Image.Ready

            // Retry with lowercase class on first failure
            property bool retried: false
            onStatusChanged: {
                if (status === Image.Error && !retried) {
                    retried = true
                    source = "image://theme/" + (root.client.class_ || "").toLowerCase()
                }
            }
        }

        // ── Letter fallback ───────────────────────────────────────────────────
        Item {
            id: iconFallback
            anchors.fill: parent
            visible:      iconImage.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text:       (root.client.class_ || "?").charAt(0).toUpperCase()
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
            border.color: root.hovered ? Qt.rgba(1, 1, 1, 0.22) : "transparent"
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

        color:   root.isActive ? panel.cGreen : Qt.rgba(1, 1, 1, 0.30)
        opacity: root.isActive ? 1.0 : 0.55

        Behavior on color   { ColorAnimation  { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ── Workspace badge ───────────────────────────────────────────────────────
    // Positioned using computed scaled coordinates so it stays glued to the
    // top-right corner of the magnified icon regardless of scale value.
    Rectangle {
        visible: !root.isActive

        // Badge size (fixed)
        readonly property real bw: Math.max(badgeTxt.implicitWidth + 8, 18)
        readonly property real bh: 18

        implicitWidth:  bw
        implicitHeight: bh
        radius:         9

        // Track the scaled icon's top-right corner.
        // iconRect's unscaled top-right in parent coords:
        //   cx = parent.width/2   (iconRect is horizontalCenter)
        //   cy = parent.height/2 - 5 (verticalCenterOffset)
        // After applying scale the top-right shifts by:
        //   dx = (iconBase/2) * scale
        //   dy = -(iconBase/2) * scale
        property real scaledHalf: (panel.iconBase / 2) * iconRect.scale
        property real cx:         parent.width / 2
        property real cy:         parent.height / 2 - 5

        x: cx + scaledHalf - bw + 3
        y: cy - scaledHalf - 3

        color:        panel.cOverlay
        border.color: Qt.rgba(0, 0, 0, 0.45)
        border.width: 1

        Text {
            id: badgeTxt
            anchors.centerIn: parent
            text:             root.client.workspace ? root.client.workspace.id : ""
            font.pixelSize:   9
            font.weight:      Font.Bold
            color:            panel.cSubtext
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited:  root.hovered = false

        onClicked: {
            bounceAnim.restart()
            root.focusRequested(root.client.address)
        }
    }

    // ── Deterministic colour from class name (for fallback bg) ────────────────
    function iconColor() {
        var cls  = root.client.class_ || "?"
        var hash = 0
        for (var i = 0; i < cls.length; i++)
            hash = (hash * 31 + cls.charCodeAt(i)) & 0xFFFFFF

        var h = (hash        & 0xFF) / 255
        var s = 0.50 + ((hash >> 8  & 0xFF) / 255) * 0.35
        var v = 0.52 + ((hash >> 16 & 0xFF) / 255) * 0.22
        return Qt.hsva(h, s, v, 1)
    }
}
