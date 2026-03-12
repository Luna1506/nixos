// ─── BatteryRow.qml ───────────────────────────────────────────────────────────
// Battery row with percentage bar.

import QtQuick
import QtQuick.Layouts

Rectangle {
    required property var    panel
    required property int    pct
    required property string status

    implicitHeight: 52
    color:          panel.cSurface
    radius:         10

    ColumnLayout {
        anchors {
            fill:        parent
            leftMargin:  14
            rightMargin: 14
            topMargin:   8
            bottomMargin: 8
        }
        spacing: 6

        RowLayout {
            spacing: 10

            Text {
                text: {
                    if (status === "Charging")    return ""
                    if (pct > 80)                 return ""
                    if (pct > 40)                 return ""
                    if (pct > 15)                 return ""
                    return ""
                }
                font.pixelSize: 16
                color: {
                    if (status === "Charging")    return panel.cGreen
                    if (pct > 40)                 return panel.cText
                    if (pct > 15)                 return panel.cYellow
                    return panel.cRed
                }
            }

            Text {
                text:           "Battery"
                font.pixelSize: 13
                color:          panel.cSubtext
                font.weight:    Font.Medium
            }

            Item { Layout.fillWidth: true }

            Text {
                text:           pct + "%  " + status
                font.pixelSize: 13
                color:          panel.cText
            }
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            height:           4
            radius:           2
            color:            panel.cOverlay

            Rectangle {
                width: parent.width * (pct / 100)
                height: parent.height
                radius: parent.radius
                color: {
                    if (status === "Charging") return panel.cGreen
                    if (pct > 40)              return panel.cAccent
                    if (pct > 15)              return panel.cYellow
                    return panel.cRed
                }

                Behavior on width {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
