// ─── WifiDropdown.qml ─────────────────────────────────────────────────────────
// Expandable WiFi row with scrollable network list.

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
    property var    networks:      []
    property string selectedSSID:  ""
    property bool   needsPassword: false
    property string statusMsg:     ""

    // ── Collapsed: only header. Expanded: header + fixed 200px list area. ──────
    readonly property int listMaxHeight: 200
    readonly property int pwRowHeight:   52
    readonly property int statusRowH:    24
    readonly property int dividerH:      9  // divider + spacing

    implicitHeight: {
        var h = headerRow.height
        if (!expanded) return h
        h += dividerH
        h += Math.min(root.networks.length * 44, listMaxHeight)
        if (needsPassword) h += pwRowHeight
        if (statusMsg.length > 0) h += statusRowH
        h += 10  // bottom padding
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
            if (running) { collected = [] }
            else { root.networks = collected.slice() }
        }
    }

    Process {
        id: statusProc
        command: ["sh", "-c",
            "nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}' | head -1"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var s = line.trim()
                root.connectedSSID = s.length > 0 ? s : "Not connected"
                root.connected     = s.length > 0
            }
        }
    }

    Process {
        id: connectProc
        running: false
        onRunningChanged: {
            if (!running) {
                root.statusMsg = ""
                statusProc.running = false; statusProc.running = true
                scanProc.running   = false; scanProc.running   = true
            }
        }
    }

    Component.onCompleted: { statusProc.running = true }

    onExpandedChanged: {
        if (expanded) {
            scanProc.running   = false; scanProc.running   = true
            statusProc.running = false; statusProc.running = true
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

        Rectangle {
            width: 32; height: 32; radius: 8
            color: Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.15)
            Text {
                anchors.centerIn: parent
                text:           root.connected ? "" : ""
                font.pixelSize: 18
                color:          root.connected ? panel.cNeonCyan : panel.cNeonPink
            }
        }

        Text {
            text: "WiFi"; font.pixelSize: 13; font.weight: Font.Medium; color: panel.cSubtext
        }

        Item { Layout.fillWidth: true }

        Text {
            text: root.connectedSSID; font.pixelSize: 13; color: panel.cText
            elide: Text.ElideRight; Layout.maximumWidth: 180
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
        visible:  root.expanded
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

        // Scrollable network list
        ListView {
            id: networkList
            anchors {
                top:    divider.bottom
                left:   parent.left
                right:  parent.right
                topMargin: 4
            }
            height:      Math.min(root.networks.length * 44, root.listMaxHeight)
            clip:        true
            model:       root.networks
            spacing:     2
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                width: 4
                contentItem: Rectangle {
                    implicitWidth: 4; implicitHeight: 30; radius: 2
                    color: Qt.rgba(0.659, 0.333, 0.969, 0.5)
                }
                background: Rectangle { color: "transparent" }
            }

            delegate: Rectangle {
                width:          networkList.width
                height:         44
                radius:         8
                color: {
                    if (modelData.ssid === root.connectedSSID)
                        return Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.15)
                    if (modelData.ssid === root.selectedSSID)
                        return Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.07)
                    return "transparent"
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 8

                    Text {
                        text: {
                            var s = modelData.signal
                            if (s >= 75) return ""
                            if (s >= 50) return ""
                            if (s >= 25) return ""
                            return ""
                        }
                        font.pixelSize: 14
                        color: modelData.ssid === root.connectedSSID ? panel.cNeonCyan : panel.cSubtext
                    }

                    Text {
                        text: modelData.ssid; font.pixelSize: 13
                        color: modelData.ssid === root.connectedSSID ? panel.cNeonCyan : panel.cText
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }

                    Text {
                        visible: modelData.secured; text: ""
                        font.pixelSize: 11; color: panel.cSubtext
                    }

                    Text {
                        visible: modelData.ssid === root.connectedSSID; text: ""
                        font.pixelSize: 13; color: panel.cNeonCyan
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.ssid === root.connectedSSID) {
                            root.statusMsg     = "Disconnecting…"
                            root.selectedSSID  = ""
                            root.needsPassword = false
                            connectProc.command = ["nmcli", "dev", "disconnect", "wlan0"]
                            connectProc.running = false; connectProc.running = true
                        } else {
                            root.selectedSSID  = modelData.ssid
                            root.needsPassword = modelData.secured
                            root.statusMsg     = ""
                            if (!modelData.secured) {
                                root.statusMsg = "Connecting…"
                                connectProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid]
                                connectProc.running = false; connectProc.running = true
                            }
                        }
                    }
                }
            }
        }

        // Password row
        Rectangle {
            id: pwRow
            anchors {
                top:    networkList.bottom
                left:   parent.left
                right:  parent.right
                topMargin: 4
            }
            height:   root.needsPassword ? root.pwRowHeight : 0
            visible:  root.needsPassword
            radius:   8
            color:    Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.07)
            border.color: panel.cBorder; border.width: 1

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 8

                TextField {
                    id: pwField
                    Layout.fillWidth:     true
                    placeholderText:      "Password…"
                    echoMode:             TextInput.Password
                    font.pixelSize:       13
                    background:           Rectangle { color: "transparent" }
                    color:                panel.cText
                    placeholderTextColor: panel.cSubtext
                    Keys.onReturnPressed: doConnect()
                }

                Rectangle {
                    implicitWidth: 80; implicitHeight: 30; radius: 6
                    color:        Qt.rgba(panel.cNeonCyan.r, panel.cNeonCyan.g, panel.cNeonCyan.b, 0.2)
                    border.color: panel.cNeonCyan; border.width: 1
                    Text { anchors.centerIn: parent; text: "Connect"; font.pixelSize: 12; color: panel.cNeonCyan }
                    MouseArea { anchors.fill: parent; onClicked: doConnect() }
                }
            }
        }

        // Status text
        Text {
            anchors {
                top:              pwRow.bottom
                horizontalCenter: parent.horizontalCenter
                topMargin:        4
            }
            visible:        root.statusMsg.length > 0
            text:           root.statusMsg
            font.pixelSize: 12
            color:          panel.cNeonCyan
        }
    }

    function doConnect() {
        if (pwField.text.length > 0) {
            root.statusMsg     = "Connecting…"
            root.needsPassword = false
            connectProc.command = ["nmcli", "dev", "wifi", "connect", root.selectedSSID, "password", pwField.text]
            connectProc.running = false; connectProc.running = true
            pwField.text = ""
        }
    }
}
