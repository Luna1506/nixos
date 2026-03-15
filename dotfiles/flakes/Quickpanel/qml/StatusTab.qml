// ─── StatusTab.qml ────────────────────────────────────────────────────────────
// Tab 1: Clock / Date, WiFi (dropdown), Bluetooth (dropdown), Battery.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Reference to the parent panel (for colours)
    required property var panel

    implicitHeight: col.implicitHeight + 8

    // ── State ──────────────────────────────────────────────────────────────────
    property int    batteryPct:     0
    property string batteryStatus:  "Unknown"   // Charging / Discharging / Full

    // ── Refresh timer (every 8 s) ──────────────────────────────────────────────
    Timer {
        interval: 8000
        repeat:   true
        running:  true
        triggeredOnStart: true
        onTriggered: {
            batProc.running = false
            batProc.running = true
        }
    }

    // ── Clock timer (every 1 s) ────────────────────────────────────────────────
    Timer {
        interval: 1000
        repeat:   true
        running:  true
        triggeredOnStart: true
        onTriggered: clockLabel.updateTime()
    }

    // ── Battery process ────────────────────────────────────────────────────────
    Process {
        id: batProc
        command: ["sh", "-c",
            "echo $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); echo $(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var s = line.trim()
                var n = parseInt(s)
                if (!isNaN(n) && s.match(/^\d+$/)) {
                    root.batteryPct = n
                } else if (s.length > 0) {
                    root.batteryStatus = s.charAt(0).toUpperCase() + s.slice(1)
                }
            }
        }
    }

    // ── UI ─────────────────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right }
        spacing: 8

        // ── Clock / date block ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   100
            color:            panel.cCard
            radius:           12
            border.color:     panel.cBorder
            border.width:     1
            clip:             true

            // Battery % — top right overlay
            Text {
                anchors {
                    top:         parent.top
                    right:       parent.right
                    topMargin:   8
                    rightMargin: 10
                }
                text:           root.batteryPct + "%"
                font.pixelSize: 11
                font.weight:    Font.Medium
                color: {
                    if (root.batteryStatus === "Charging") return panel.cNeonCyan
                    if (root.batteryPct >= 41)             return panel.cSubtext
                    if (root.batteryPct >= 16)             return panel.cNeonYellow
                    return panel.cNeonPink
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:  clockLabel.implicitWidth
                    height: clockLabel.implicitHeight

                    // Glow layer (same size as main clock)
                    Text {
                        anchors.centerIn: parent
                        font.pixelSize:   48
                        font.weight:      Font.Light
                        color:            panel.cNeonCyan
                        opacity:          0.30
                        text:             clockLabel.timeStr
                    }

                    // Main clock
                    Text {
                        id: clockLabel
                        anchors.centerIn: parent
                        font.pixelSize:   48
                        font.weight:      Font.Light
                        color:            panel.cNeonCyan

                        property string timeStr: ""
                        property string dateStr: ""

                        text: timeStr

                        function updateTime() {
                            var d   = new Date()
                            var h   = d.getHours().toString().padStart(2, "0")
                            var m   = d.getMinutes().toString().padStart(2, "0")
                            var s   = d.getSeconds().toString().padStart(2, "0")
                            timeStr = h + ":" + m + ":" + s

                            var days   = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
                            var months = ["Jan","Feb","Mar","Apr","May","Jun",
                                          "Jul","Aug","Sep","Oct","Nov","Dec"]
                            dateStr = days[d.getDay()] + ", " +
                                      d.getDate() + " " + months[d.getMonth()] +
                                      " " + d.getFullYear()
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text:             clockLabel.dateStr
                    font.pixelSize:   14
                    color:            panel.cSubtext
                }
            }
        }

        // ── WiFi dropdown ──────────────────────────────────────────────────────
        WifiDropdown {
            Layout.fillWidth: true
            panel: root.panel
        }

        // ── Bluetooth dropdown ─────────────────────────────────────────────────
        BluetoothDropdown {
            Layout.fillWidth: true
            panel: root.panel
        }

        // Bottom padding
        Item { implicitHeight: 4 }
    }
}
