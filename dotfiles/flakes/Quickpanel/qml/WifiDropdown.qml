// ─── WifiDropdown.qml ─────────────────────────────────────────────────────────
// Expandable WiFi row: lists visible networks, connects with password if needed.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root

    required property var panel

    // ── State ──────────────────────────────────────────────────────────────────
    property bool   expanded:      false
    property string connectedSSID: "—"
    property bool   connected:     false
    property var    networks:      []   // [{ssid, signal, secured}]
    property string selectedSSID:  ""
    property bool   needsPassword: false
    property string statusMsg:     ""

    // ── Size ──────────────────────────────────────────────────────────────────
    implicitHeight: headerRow.height + (expanded ? dropContent.implicitHeight : 0)
    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    color:  panel.cCard
    radius: 10
    border.color: panel.cBorder
    border.width: 1

    // ── Processes ──────────────────────────────────────────────────────────────

    // List visible networks
    Process {
        id: scanProc
        command: ["sh", "-c",
            "nmcli -t -f ssid,signal,security dev wifi list 2>/dev/null | sort -t: -k2 -rn | awk -F: '!seen[$1]++ && $1!=\"\"'"]
        running: false
        property var collected: []
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var parts = line.split(":")
                if (parts.length >= 2 && parts[0].trim().length > 0) {
                    scanProc.collected.push({
                        ssid:    parts[0].trim(),
                        signal:  parseInt(parts[1]) || 0,
                        secured: parts.length >= 3 && parts[2].trim().length > 0
                    })
                }
            }
        }
        onRunningChanged: {
            if (running) {
                collected = []
            } else {
                root.networks = collected.slice()
            }
        }
    }

    // Get current connection
    Process {
        id: statusProc
        command: ["sh", "-c",
            "nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}' | head -1"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var s = line.trim()
                if (s.length > 0) {
                    root.connectedSSID = s
                    root.connected     = true
                } else {
                    root.connectedSSID = "Not connected"
                    root.connected     = false
                }
            }
        }
    }

    // Connect / disconnect
    Process {
        id: connectProc
        running: false
        onRunningChanged: {
            if (!running) {
                root.statusMsg = ""
                statusProc.running = false
                statusProc.running = true
                scanProc.running   = false
                scanProc.running   = true
            }
        }
    }

    // ── Init ──────────────────────────────────────────────────────────────────
    Component.onCompleted: {
        statusProc.running = true
    }

    // Refresh when expanded
    onExpandedChanged: {
        if (expanded) {
            scanProc.running   = false
            scanProc.running   = true
            statusProc.running = false
            statusProc.running = true
        } else {
            selectedSSID  = ""
            needsPassword = false
            statusMsg     = ""
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────
    RowLayout {
        id: headerRow
        anchors { left: parent.left; right: parent.right }
        height: 56
        spacing: 10

        anchors.leftMargin:  14
        anchors.rightMargin: 14

        // Icon badge
        Rectangle {
            width:  32
            height: 32
            radius: 8
            color:  Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.15)

            Text {
                anchors.centerIn: parent
                text:           root.connected ? "" : ""
                font.pixelSize: 18
                color:          root.connected ? panel.cNeonCyan : panel.cNeonPink
            }
        }

        Text {
            text:           "WiFi"
            font.pixelSize: 13
            font.weight:    Font.Medium
            color:          panel.cSubtext
        }

        Item { Layout.fillWidth: true }

        Text {
            text:           root.connectedSSID
            font.pixelSize: 13
            color:          panel.cText
            elide:          Text.ElideRight
            Layout.maximumWidth: 180
        }

        Text {
            text:           root.expanded ? "" : ""
            font.pixelSize: 12
            color:          panel.cSubtext
        }

        MouseArea {
            anchors.fill: parent
            onClicked:    root.expanded = !root.expanded
        }
    }

    // ── Dropdown content ──────────────────────────────────────────────────────
    ColumnLayout {
        id: dropContent
        anchors {
            top:         headerRow.bottom
            left:        parent.left
            right:       parent.right
            leftMargin:  10
            rightMargin: 10
        }
        spacing: 4

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color:  panel.cBorder
        }

        // Network list
        Repeater {
            model: root.networks

            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight:   44
                radius:           8
                color: {
                    if (modelData.ssid === root.connectedSSID)
                        return Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.12)
                    if (modelData.ssid === root.selectedSSID)
                        return Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.07)
                    return "transparent"
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 8

                    // Signal strength bars
                    Text {
                        text: {
                            var s = modelData.signal
                            if (s >= 75) return ""
                            if (s >= 50) return ""
                            if (s >= 25) return ""
                            return ""
                        }
                        font.pixelSize: 14
                        color: modelData.ssid === root.connectedSSID
                               ? panel.cNeonCyan : panel.cSubtext
                    }

                    Text {
                        text:           modelData.ssid
                        font.pixelSize: 13
                        color:          modelData.ssid === root.connectedSSID
                                        ? panel.cNeonCyan : panel.cText
                        elide:          Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Lock icon if secured
                    Text {
                        visible:        modelData.secured
                        text:           ""
                        font.pixelSize: 11
                        color:          panel.cSubtext
                    }

                    // Connected indicator
                    Text {
                        visible:        modelData.ssid === root.connectedSSID
                        text:           ""
                        font.pixelSize: 13
                        color:          panel.cNeonCyan
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.ssid === root.connectedSSID) {
                            // Disconnect
                            root.statusMsg     = "Disconnecting…"
                            root.selectedSSID  = ""
                            root.needsPassword = false
                            connectProc.command = ["nmcli", "dev", "disconnect", "wlan0"]
                            connectProc.running = false
                            connectProc.running = true
                        } else {
                            root.selectedSSID  = modelData.ssid
                            root.needsPassword = modelData.secured
                            root.statusMsg     = ""
                            if (!modelData.secured) {
                                // Connect directly (open network)
                                root.statusMsg = "Connecting…"
                                connectProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid]
                                connectProc.running = false
                                connectProc.running = true
                            }
                        }
                    }
                }
            }
        }

        // Password field (shown when secured network selected)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   visible ? 44 : 0
            visible:          root.needsPassword
            radius:           8
            color:            Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.07)
            border.color:     panel.cBorder
            border.width:     1

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 8

                TextField {
                    id: pwField
                    Layout.fillWidth: true
                    placeholderText:  "Password…"
                    echoMode:         TextInput.Password
                    font.pixelSize:   13

                    background: Rectangle { color: "transparent" }

                    color:                panel.cText
                    placeholderTextColor: panel.cSubtext

                    Keys.onReturnPressed: connectBtn.clicked()
                }

                Rectangle {
                    id: connectBtn
                    implicitWidth:  80
                    implicitHeight: 30
                    radius:         6
                    color:          Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.2)
                    border.color:   panel.cNeonCyan
                    border.width:   1

                    signal clicked

                    Text {
                        anchors.centerIn: parent
                        text:           "Connect"
                        font.pixelSize: 12
                        color:          panel.cNeonCyan
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (pwField.text.length > 0) {
                                root.statusMsg     = "Connecting…"
                                root.needsPassword = false
                                connectProc.command = [
                                    "nmcli", "dev", "wifi", "connect",
                                    root.selectedSSID, "password", pwField.text
                                ]
                                connectProc.running = false
                                connectProc.running = true
                                pwField.text = ""
                            }
                        }
                    }
                }
            }
        }

        // Status message
        Text {
            visible:        root.statusMsg.length > 0
            text:           root.statusMsg
            font.pixelSize: 12
            color:          panel.cNeonCyan
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 4
        }

        Item { implicitHeight: 6 }
    }
}
