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

    implicitHeight: 44
    color:          panel.cSurface
    radius:         10

    RowLayout {
        anchors {
            fill:           parent
            leftMargin:     14
            rightMargin:    14
        }
        spacing: 10

        // Icon
        Text {
            text:           icon
            font.pixelSize: 16
            color:          iconColor
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
            font.pixelSize:      13
            color:               panel.cText
            elide:               Text.ElideRight
            Layout.maximumWidth: 170
        }
    }
}
