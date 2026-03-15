// ─── BluetoothDropdown.qml ────────────────────────────────────────────────────
// Expandable Bluetooth row with scrollable device list, scan + pair.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root

    required property var panel

    // ── State ──────────────────────────────────────────────────────────────────
    property bool   expanded:        false
    property bool   btEnabled:       false
    property string connectedDevice: ""
    property var    devices:         []
    property bool   scanning:        false
    property string statusMsg:       ""

    // ── Height calculation ────────────────────────────────────────────────────
    readonly property int listMaxHeight: 200
    readonly property int scanBarHeight: 40
    readonly property int statusRowH:    24

    implicitHeight: {
        var h = headerRow.height
        if (!expanded) return h
        h += 9   // divider + spacing
        h += scanBarHeight
        h += Math.min(root.devices.length * 52, listMaxHeight)
        if (statusMsg.length > 0) h += statusRowH
        h += 10
        return h
    }
    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    color:  panel.cCard
    radius: 10
    border.color: panel.cBorder
    border.width: 1

    // ── Processes ──────────────────────────────────────────────────────────────

    Process {
        id: statusProc
        command: ["sh", "-c", [
            "POWERED=$(bluetoothctl show 2>/dev/null | grep -c 'Powered: yes')",
            "CONN=$(bluetoothctl info 2>/dev/null | grep 'Name:' | sed 's/.*Name: //' | head -1)",
            "printf '%s\\n%s\\n' \"$POWERED\" \"$CONN\""
        ].join("; ")]
        running: false
        property var lines: []
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) { statusProc.lines.push(line) }
        }
        onRunningChanged: {
            if (running) { lines = [] }
            else if (lines.length >= 1) {
                root.btEnabled       = (lines[0].trim() === "1")
                root.connectedDevice = lines.length >= 2 ? lines[1].trim() : ""
            }
        }
    }

    Process {
        id: devicesProc
        command: ["sh", "-c",
            "bluetoothctl devices 2>/dev/null | sed 's/Device //' | while read mac name; do " +
            "  info=$(bluetoothctl info $mac 2>/dev/null); " +
            "  connected=$(echo \"$info\" | grep -c 'Connected: yes'); " +
            "  paired=$(echo \"$info\" | grep -c 'Paired: yes'); " +
            "  echo \"$mac|$name|$connected|$paired\"; " +
            "done"]
        running: false
        property var collected: []
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var parts = line.split("|")
                if (parts.length >= 4 && parts[0].trim().length > 0) {
                    devicesProc.collected.push({
                        mac:       parts[0].trim(),
                        name:      parts[1].trim() || parts[0].trim(),
                        connected: parts[2].trim() === "1",
                        paired:    parts[3].trim() === "1"
                    })
                }
            }
        }
        onRunningChanged: {
            if (running) { collected = [] }
            else { root.devices = collected.slice() }
        }
    }

    Process {
        id: scanStartProc
        command: ["bluetoothctl", "scan", "on"]
        running: false
    }

    Timer {
        id: scanTimer
        interval: 10000
        repeat:   false
        onTriggered: {
            scanStopProc.running = false; scanStopProc.running = true
        }
    }

    Process {
        id: scanStopProc
        command: ["bluetoothctl", "scan", "off"]
        running: false
        onRunningChanged: {
            if (!running) {
                root.scanning = false
                devicesProc.running = false; devicesProc.running = true
            }
        }
    }

    Process {
        id: cmdProc
        running: false
        onRunningChanged: {
            if (!running) {
                root.statusMsg = ""
                statusProc.running  = false; statusProc.running  = true
                devicesProc.running = false; devicesProc.running = true
            }
        }
    }

    Component.onCompleted: { statusProc.running = true }

    onExpandedChanged: {
        if (expanded) {
            statusProc.running  = false; statusProc.running  = true
            devicesProc.running = false; devicesProc.running = true
        } else {
            scanning  = false
            statusMsg = ""
            scanTimer.stop()
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────
    RowLayout {
        id: headerRow
        anchors { left: parent.left; right: parent.right }
        height: 56; spacing: 10
        anchors.leftMargin: 14; anchors.rightMargin: 14

        Rectangle {
            width: 32; height: 32; radius: 8
            color: Qt.rgba(panel.cNeonPink.r, panel.cNeonPink.g, panel.cNeonPink.b, 0.15)
            Text {
                anchors.centerIn: parent; text: ""
                font.pixelSize: 18
                color: root.btEnabled ? panel.cNeonPink : panel.cSubtext
            }
        }

        Text { text: "Bluetooth"; font.pixelSize: 13; font.weight: Font.Medium; color: panel.cSubtext }

        Item { Layout.fillWidth: true }

        Text {
            text: root.connectedDevice.length > 0 ? root.connectedDevice
                  : (root.btEnabled ? "On" : "Off")
            font.pixelSize: 13; color: panel.cText
            elide: Text.ElideRight; Layout.maximumWidth: 160
        }

        Text {
            text: root.expanded ? "" : ""
            font.pixelSize: 12; color: panel.cSubtext
        }

        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    // ── Dropdown body ─────────────────────────────────────────────────────────
    Item {
        id: dropBody
        visible: root.expanded
        anchors {
            top:         headerRow.bottom
            left:        parent.left
            right:       parent.right
            bottom:      parent.bottom
            leftMargin:  10
            rightMargin: 10
        }

        // Divider
        Rectangle {
            id: divider
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1; color: panel.cBorder
        }

        // Scan bar
        Item {
            id: scanBar
            anchors { top: divider.bottom; left: parent.left; right: parent.right; topMargin: 4 }
            height: root.scanBarHeight - 4

            // Spinner + label
            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 6
                visible: root.scanning

                Text {
                    id: spinnerIcon; text: ""; font.pixelSize: 16; color: panel.cNeonPink
                    RotationAnimation on rotation {
                        running: root.scanning; from: 0; to: 360
                        duration: 1000; loops: Animation.Infinite
                    }
                }
                Text { text: "Scanning…"; font.pixelSize: 12; color: panel.cNeonPink }
            }

            // Scan button
            Rectangle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                implicitWidth: 90; implicitHeight: 28; radius: 6
                color:        root.scanning
                              ? Qt.rgba(panel.cNeonPink.r, panel.cNeonPink.g, panel.cNeonPink.b, 0.25)
                              : Qt.rgba(panel.cNeonPink.r, panel.cNeonPink.g, panel.cNeonPink.b, 0.12)
                border.color: panel.cNeonPink; border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.scanning ? "Scanning" : " Scan"
                    font.pixelSize: 12; color: panel.cNeonPink
                }
                MouseArea {
                    anchors.fill: parent; enabled: !root.scanning
                    onClicked: {
                        root.scanning = true
                        scanStartProc.running = false; scanStartProc.running = true
                        scanTimer.restart()
                    }
                }
            }
        }

        // Scrollable device list
        ListView {
            id: deviceList
            anchors {
                top:    scanBar.bottom
                left:   parent.left
                right:  parent.right
                topMargin: 4
            }
            height:         Math.min(root.devices.length * 52, root.listMaxHeight)
            clip:           true
            model:          root.devices
            spacing:        2
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                width: 4
                contentItem: Rectangle {
                    implicitWidth: 4; implicitHeight: 30; radius: 2
                    color: Qt.rgba(0.933, 0.286, 0.6, 0.5)
                }
                background: Rectangle { color: "transparent" }
            }

            delegate: Rectangle {
                width:  deviceList.width
                height: 50
                radius: 8
                color:  modelData.connected
                        ? Qt.rgba(panel.cNeonPink.r, panel.cNeonPink.g, panel.cNeonPink.b, 0.15)
                        : "transparent"

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 8

                    Text {
                        text: modelData.paired ? "" : ""
                        font.pixelSize: 14
                        color: modelData.connected ? panel.cNeonPink : panel.cSubtext
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text {
                            text: modelData.name; font.pixelSize: 13
                            color: modelData.connected ? panel.cNeonPink : panel.cText
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.connected ? "Connected"
                                  : (modelData.paired ? "Paired" : "New device")
                            font.pixelSize: 10; color: panel.cSubtext
                        }
                    }

                    Rectangle {
                        implicitWidth: 76; implicitHeight: 26; radius: 5
                        color:        Qt.rgba(panel.cNeonPink.r, panel.cNeonPink.g, panel.cNeonPink.b, 0.15)
                        border.color: panel.cNeonPink; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.connected ? "Disconnect"
                                  : (modelData.paired ? "Connect" : "Pair")
                            font.pixelSize: 11; color: panel.cNeonPink
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData.connected) {
                                    root.statusMsg = "Disconnecting…"
                                    cmdProc.command = ["bluetoothctl", "disconnect", modelData.mac]
                                } else if (modelData.paired) {
                                    root.statusMsg = "Connecting…"
                                    cmdProc.command = ["bluetoothctl", "connect", modelData.mac]
                                } else {
                                    root.statusMsg = "Pairing…"
                                    cmdProc.command = ["sh", "-c",
                                        "bluetoothctl trust " + modelData.mac +
                                        " && bluetoothctl pair " + modelData.mac +
                                        " && bluetoothctl connect " + modelData.mac]
                                }
                                cmdProc.running = false; cmdProc.running = true
                            }
                        }
                    }
                }
            }
        }

        // Empty state
        Text {
            anchors { top: deviceList.bottom; horizontalCenter: parent.horizontalCenter; topMargin: 6 }
            visible:        root.devices.length === 0 && !root.scanning
            text:           "No devices found. Tap Scan."
            font.pixelSize: 12; color: panel.cSubtext
        }

        // Status message
        Text {
            anchors { top: deviceList.bottom; horizontalCenter: parent.horizontalCenter; topMargin: 6 }
            visible:        root.statusMsg.length > 0
            text:           root.statusMsg
            font.pixelSize: 12; color: panel.cNeonPink
        }
    }
}
