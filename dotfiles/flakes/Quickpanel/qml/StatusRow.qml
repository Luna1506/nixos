// ─── StatusRow.qml ────────────────────────────────────────────────────────────
// Generic icon + label + value row for the status tab.

import QtQuick
import QtQuick.Layouts

Rectangle {
    required property var    panel
    required property string icon
    required property color  iconColor
    required property string label
    required property string value
    property color badgeColor: "transparent"

    implicitHeight: 68
    color:          panel.cCard
    radius:         10

    RowLayout {
        anchors {
            fill:           parent
            leftMargin:     14
            rightMargin:    14
        }
        spacing: 10

        // Icon badge
        Rectangle {
            width:  32
            height: 32
            radius: 8
            color:  badgeColor.a > 0 ? Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.15) : "transparent"

            Text {
                anchors.centerIn: parent
                text:           icon
                font.pixelSize: 20
                color:          iconColor
            }
        }

        // Label
        Text {
            text:           label
            font.pixelSize: 13
            color:          panel.cSubtext
            font.weight:    Font.Medium
        }

        Item { Layout.fillWidth: true }

        // Value
        Text {
            text:                value
            font.pixelSize:      15
            color:               panel.cText
            elide:               Text.ElideRight
            Layout.maximumWidth: 240
        }
    }
}
