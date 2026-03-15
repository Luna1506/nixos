// ─── BatteryRow.qml ───────────────────────────────────────────────────────────
// Battery row with percentage bar.

import QtQuick
import QtQuick.Layouts

Rectangle {
    required property var    panel
    required property int    pct
    required property string status

    implicitHeight: 84
    color:          panel.cCard
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

            // Battery icon badge
            Rectangle {
                width:  32
                height: 32
                radius: 8
                color:  Qt.rgba(panel.cNeonViolet.r, panel.cNeonViolet.g, panel.cNeonViolet.b, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (status === "Charging")    return ""
                        if (pct > 80)                 return ""
                        if (pct > 40)                 return ""
                        if (pct > 15)                 return ""
                        return ""
                    }
                    font.pixelSize: 18
                    color: {
                        if (status === "Charging")    return panel.cNeonCyan
                        if (pct >= 41)                return panel.cText
                        if (pct >= 16)                return panel.cNeonYellow
                        return panel.cNeonPink
                    }
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
                font.pixelSize: 15
                color:          panel.cText
            }
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            height:           6
            radius:           3
            color:            panel.cBorder

            Rectangle {
                width: parent.width * (pct / 100)
                height: parent.height
                radius: parent.radius
                color: {
                    if (status === "Charging") return panel.cNeonCyan
                    if (pct >= 41)             return panel.cNeonViolet
                    if (pct >= 16)             return panel.cNeonYellow
                    return panel.cNeonPink
                }

                Behavior on width {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
