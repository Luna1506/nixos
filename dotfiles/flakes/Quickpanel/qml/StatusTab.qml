// ─── StatusTab.qml ────────────────────────────────────────────────────────────
// Tab 1: Clock / Date, WiFi, Bluetooth, Battery.
// Data is fetched via short-lived child processes (nmcli, bluetoothctl, upower).

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
    property string wifiSSID:     "—"
    property bool   wifiConnected: false

    property string btStatus:  "Off"
    property string btDevice:  ""
    property bool   btEnabled: false

    property int    batteryPct:     0
    property string batteryStatus:  "Unknown"   // Charging / Discharging / Full

    // ── Refresh timer (every 8 s) ──────────────────────────────────────────────
    Timer {
        interval: 8000
        repeat:   true
        running:  root.visible || true   // keep running even when hidden
        triggeredOnStart: true
        onTriggered: {
            wifiProc.running = false
            wifiProc.running = true
            btProc.running   = false
            btProc.running   = true
            batProc.running  = false
            batProc.running  = true
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

    // ─── Processes ─────────────────────────────────────────────────────────────

    // WiFi: get active SSID
    Process {
        id: wifiProc
        command: ["sh", "-c",
            "nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}' | head -1"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var s = line.trim()
                if (s.length > 0) {
                    root.wifiSSID      = s
                    root.wifiConnected = true
                } else {
                    root.wifiSSID      = "Not connected"
                    root.wifiConnected = false
                }
            }
        }
    }

    // Bluetooth: powered + connected device name
    Process {
        id: btProc
        command: ["sh", "-c",
            "bluetoothctl show 2>/dev/null | grep -c 'Powered: yes'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                root.btEnabled = (line.trim() === "1")
                root.btStatus  = root.btEnabled ? "On" : "Off"
            }
        }
    }

    // Battery: percentage and status from upower
    Process {
        id: batProc
        command: ["sh", "-c",
            "upower -i $(upower -e | grep BAT | head -1) 2>/dev/null | grep -E 'percentage|state' | awk '{print $2}'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var s = line.trim()
                if (s.endsWith("%")) {
                    root.batteryPct = parseInt(s)
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

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: clockLabel.width
                    height: clockLabel.height

                    // Glow layer
                    Text {
                        anchors.centerIn: parent
                        font.pixelSize:   52
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

        // ── WiFi ───────────────────────────────────────────────────────────────
        StatusRow {
            panel:      root.panel
            icon:       root.wifiConnected ? "" : ""
            iconColor:  root.wifiConnected ? panel.cNeonCyan : panel.cNeonPink
            badgeColor: panel.cNeonCyan
            label:      "WiFi"
            value:      root.wifiSSID
        }

        // ── Bluetooth ──────────────────────────────────────────────────────────
        StatusRow {
            panel:      root.panel
            icon:       ""
            iconColor:  root.btEnabled ? panel.cNeonPink : panel.cSubtext
            badgeColor: panel.cNeonPink
            label:      "Bluetooth"
            value:      root.btStatus + (root.btDevice.length > 0
                            ? "  ·  " + root.btDevice : "")
        }

        // ── Battery ────────────────────────────────────────────────────────────
        BatteryRow {
            panel:   root.panel
            pct:     root.batteryPct
            status:  root.batteryStatus
        }

        // Bottom padding
        Item { implicitHeight: 4 }
    }
}
