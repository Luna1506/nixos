// ─── PlayerTab.qml ────────────────────────────────────────────────────────────
// Tab 2: Media player + Volume mixer.
//
// Features
// ────────
//   • Cover art from mpris:artUrl (loaded directly over HTTPS)
//   • Playback controls with icons (prev / play-pause / next / stop)
//   • Master volume slider + mute toggle via wpctl
//   • Per-app stream volume sliders via pactl

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    required property var panel

    implicitHeight: col.implicitHeight + 8

    // ── Player state ──────────────────────────────────────────────────────────
    property string trackTitle:  "Nothing playing"
    property string trackArtist: ""
    property string trackAlbum:  ""
    property string artUrl:      ""
    property bool   isPlaying:   false
    property string playerName:  ""

    // ── Master volume state ───────────────────────────────────────────────────
    property real   masterVol:   0.65   // 0.0–1.0
    property bool   masterMuted: false

    // ── Per-app streams ───────────────────────────────────────────────────────
    // Each entry: { id, name, vol, muted }
    property var streams: []

    // ── Timers ────────────────────────────────────────────────────────────────
    Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: {
            statusProc.running = false; statusProc.running = true
            masterVolProc.running = false; masterVolProc.running = true
            streamsProc.running = false; streamsProc.running = true
        }
    }

    Timer {
        id: refreshDelay
        interval: 300; repeat: false
        onTriggered: { statusProc.running = false; statusProc.running = true }
    }

    // ── playerctl status + metadata ───────────────────────────────────────────
    Process {
        id: statusProc
        command: ["sh", "-c", [
            "STATUS=$(playerctl status 2>/dev/null)",
            "TITLE=$(playerctl metadata title 2>/dev/null)",
            "ARTIST=$(playerctl metadata artist 2>/dev/null)",
            "ALBUM=$(playerctl metadata album 2>/dev/null)",
            "PLAYER=$(playerctl -l 2>/dev/null | head -1)",
            "ART=$(playerctl metadata mpris:artUrl 2>/dev/null)",
            "printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' \"$STATUS\" \"$TITLE\" \"$ARTIST\" \"$ALBUM\" \"$PLAYER\" \"$ART\""
        ].join("; ")]
        running: false
        property var lines: []
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) { statusProc.lines.push(line) }
        }
        onRunningChanged: {
            if (running) { lines = [] }
            else if (lines.length >= 5) {
                root.isPlaying   = (lines[0].trim() === "Playing")
                root.trackTitle  = lines[1].trim() || "Nothing playing"
                root.trackArtist = lines[2].trim()
                root.trackAlbum  = lines[3].trim()
                root.playerName  = lines[4].trim()
                root.artUrl      = lines.length >= 6 ? lines[5].trim() : ""
                lines = []
            }
        }
    }

    // ── Master volume read ─────────────────────────────────────────────────────
    Process {
        id: masterVolProc
        command: ["sh", "-c",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"]
        running: false
        property var lines: []
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) { masterVolProc.lines.push(line) }
        }
        onRunningChanged: {
            if (running) { lines = [] }
            else if (lines.length > 0) {
                // Format: "Volume: 0.65" or "Volume: 0.65 [MUTED]"
                var line = lines[0]
                var m = line.match(/Volume:\s*([\d.]+)/)
                if (m) root.masterVol = parseFloat(m[1])
                root.masterMuted = line.indexOf("[MUTED]") >= 0
                lines = []
            }
        }
    }

    // ── Per-app streams via pactl ─────────────────────────────────────────────
    Process {
        id: streamsProc
        command: ["sh", "-c",
            "pactl list sink-inputs 2>/dev/null | awk '" +
            "/^Sink Input/ { id=$3 } " +
            "/application.name/ { name=$0 } " +
            "/Volume:/ && id { " +
            "  gsub(/.*\\//, \"\", $0); " +
            "  vol=$1; " +
            "  print id\"|\"name\"|\"vol " +
            "}'"]
        running: false
        property var collected: []
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var parts = line.split("|")
                if (parts.length >= 3) {
                    var id   = parts[0].replace("#", "").trim()
                    var name = parts[1].replace(/.*=\s*"?/, "").replace(/"$/, "").trim()
                    var volStr = parts[2].trim().replace("%", "")
                    var vol  = parseInt(volStr)
                    if (id && name && !isNaN(vol)) {
                        streamsProc.collected.push({ id: id, name: name, vol: vol, muted: false })
                    }
                }
            }
        }
        onRunningChanged: {
            if (running) { collected = [] }
            else { root.streams = collected.slice() }
        }
    }

    // ── Command runners ───────────────────────────────────────────────────────
    Process {
        id: cmdProc
        running: false
        onRunningChanged: { if (!running) refreshDelay.restart() }
    }

    Process { id: volProc;    running: false }
    Process { id: muteProc;   running: false; onRunningChanged: { if (!running) { masterVolProc.running = false; masterVolProc.running = true } } }
    Process { id: streamVolProc; running: false }

    function runCmd(args) {
        cmdProc.command = args
        cmdProc.running = false; cmdProc.running = true
    }

    // ── Volume slider component ───────────────────────────────────────────────
    component VolumeSlider: Slider {
        id: sldr
        property color trackColor: panel.cNeonCyan
        from: 0; to: 100; stepSize: 1

        background: Rectangle {
            x: sldr.leftPadding
            y: sldr.topPadding + sldr.availableHeight / 2 - height / 2
            width: sldr.availableWidth; height: 4; radius: 2
            color: panel.cBorder
            Rectangle {
                width: sldr.visualPosition * parent.width
                height: parent.height; radius: parent.radius
                color: sldr.trackColor
            }
        }
        handle: Rectangle {
            x: sldr.leftPadding + sldr.visualPosition * (sldr.availableWidth - width)
            y: sldr.topPadding + sldr.availableHeight / 2 - height / 2
            width: 14; height: 14; radius: 7
            color: sldr.trackColor
            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right }
        spacing: 8

        // ── Cover art + track info ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   160
            color:            panel.cCard
            radius:           12
            border.color:     panel.cBorder
            border.width:     1
            clip:             true

            // Cover art background blur (full width, dimmed)
            Image {
                anchors.fill: parent
                source:       root.artUrl
                fillMode:     Image.PreserveAspectCrop
                opacity:      0.18
                smooth:       true
                visible:      status === Image.Ready
            }

            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  14
                    rightMargin: 14
                    topMargin:   14
                    bottomMargin: 14
                }
                spacing: 14

                // Cover art square
                Rectangle {
                    width: 100; height: 100
                    radius: 10
                    color:  panel.cBorder

                    Image {
                        anchors.fill:    parent
                        anchors.margins: 0
                        source:          root.artUrl
                        fillMode:        Image.PreserveAspectCrop
                        smooth:          true
                        mipmap:          true
                        visible:         status === Image.Ready

                        layer.enabled: true
                        layer.effect: null
                    }

                    // Rounded clip mask
                    Rectangle {
                        anchors.fill:  parent
                        radius:        10
                        color:         "transparent"
                        border.color:  Qt.rgba(1, 1, 1, 0.08)
                        border.width:  1
                    }

                    // Fallback icon
                    Text {
                        anchors.centerIn: parent
                        visible:          root.artUrl === "" || parent.children[0].status !== Image.Ready
                        text:             ""
                        font.pixelSize:   36
                        color:            panel.cNeonViolet
                    }
                }

                // Track info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text:             root.trackTitle
                        font.pixelSize:   15
                        font.weight:      Font.SemiBold
                        color:            panel.cText
                        elide:            Text.ElideRight
                        wrapMode:         Text.NoWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text:             root.trackArtist
                        font.pixelSize:   12
                        color:            panel.cNeonCyan
                        elide:            Text.ElideRight
                        visible:          root.trackArtist.length > 0
                    }

                    Text {
                        Layout.fillWidth: true
                        text:             root.trackAlbum
                        font.pixelSize:   11
                        color:            panel.cSubtext
                        elide:            Text.ElideRight
                        visible:          root.trackAlbum.length > 0
                    }

                    Item { Layout.fillHeight: true }

                    // Player name badge
                    Rectangle {
                        visible:          root.playerName.length > 0
                        implicitWidth:    playerNameTxt.implicitWidth + 12
                        implicitHeight:   20
                        radius:           4
                        color:            Qt.rgba(0.627, 0.082, 0.996, 0.15)
                        border.color:     Qt.rgba(0.627, 0.082, 0.996, 0.35)
                        border.width:     1
                        Text {
                            id: playerNameTxt
                            anchors.centerIn: parent
                            text:             root.playerName
                            font.pixelSize:   10
                            color:            panel.cNeonViolet
                        }
                    }
                }
            }
        }

        // ── Playback controls ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   68
            color:            panel.cCard
            radius:           12
            border.color:     panel.cBorder
            border.width:     1

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                // Previous
                CtrlButton {
                    panel: root.panel; iconText: "⏮"; iconSize: 20
                    onClicked: root.runCmd(["playerctl", "previous"])
                }

                // Play / Pause
                CtrlButton {
                    panel:    root.panel
                    iconText: root.isPlaying ? "⏸" : "▶"
                    accent:   true; iconSize: 24
                    onClicked: root.runCmd(["playerctl", "play-pause"])
                }

                // Next
                CtrlButton {
                    panel: root.panel; iconText: "⏭"; iconSize: 20
                    onClicked: root.runCmd(["playerctl", "next"])
                }

                Rectangle { width: 1; height: 24; color: panel.cBorder }

                // Stop
                CtrlButton {
                    panel: root.panel; iconText: "⏹"; iconSize: 18
                    onClicked: root.runCmd(["playerctl", "stop"])
                }
            }
        }

        // ── Master volume ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   56
            color:            panel.cCard
            radius:           12
            border.color:     panel.cBorder
            border.width:     1

            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  14
                    rightMargin: 14
                }
                spacing: 8

                // Mute toggle
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: root.masterMuted
                        ? Qt.rgba(panel.cNeonPink.r, panel.cNeonPink.g, panel.cNeonPink.b, 0.20)
                        : Qt.rgba(0.627, 0.082, 0.996, 0.10)
                    border.color: root.masterMuted ? panel.cNeonPink : Qt.rgba(0.627, 0.082, 0.996, 0.30)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.masterMuted ? "🔇" : (root.masterVol > 0.5 ? "🔊" : (root.masterVol > 0.1 ? "🔉" : "🔈"))
                        font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
                            muteProc.running = false; muteProc.running = true
                        }
                    }
                }

                VolumeSlider {
                    id:               masterSlider
                    Layout.fillWidth: true
                    value:            root.masterMuted ? 0 : Math.round(root.masterVol * 100)
                    trackColor:       root.masterMuted ? panel.cSubtext : panel.cNeonCyan
                    enabled:          !root.masterMuted
                    onMoved: {
                        var v = (value / 100).toFixed(2)
                        volProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v]
                        volProc.running = false; volProc.running = true
                    }
                }

                Text {
                    text:            root.masterMuted ? "M" : Math.round(root.masterVol * 100) + "%"
                    font.pixelSize:  11
                    color:           root.masterMuted ? panel.cNeonPink : panel.cNeonCyan
                    Layout.minimumWidth: 28
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // ── Per-app streams ───────────────────────────────────────────────────
        Repeater {
            model: root.streams

            delegate: Rectangle {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight:   52
                color:            panel.cCard
                radius:           10
                border.color:     panel.cBorder
                border.width:     1

                RowLayout {
                    anchors {
                        fill:        parent
                        leftMargin:  14
                        rightMargin: 14
                    }
                    spacing: 8

                    Text {
                        text:           modelData.name
                        font.pixelSize: 12
                        font.weight:    Font.Medium
                        color:          panel.cText
                        elide:          Text.ElideRight
                        Layout.maximumWidth: 90
                        Layout.minimumWidth: 60
                    }

                    VolumeSlider {
                        Layout.fillWidth: true
                        value:            modelData.vol
                        trackColor:       panel.cNeonViolet
                        onMoved: {
                            var v = value + "%"
                            streamVolProc.command = ["pactl", "set-sink-input-volume", modelData.id, v]
                            streamVolProc.running = false; streamVolProc.running = true
                        }
                    }

                    Text {
                        text:            modelData.vol + "%"
                        font.pixelSize:  11
                        color:           panel.cNeonViolet
                        Layout.minimumWidth: 28
                        horizontalAlignment: Text.AlignRight
                    }

                    // Mute per stream
                    Rectangle {
                        width: 24; height: 24; radius: 6
                        color: Qt.rgba(0.627, 0.082, 0.996, 0.10)
                        border.color: Qt.rgba(0.627, 0.082, 0.996, 0.25)
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text:           "🔇"
                            font.pixelSize: 12
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                streamVolProc.command = ["pactl", "set-sink-input-mute", modelData.id, "toggle"]
                                streamVolProc.running = false; streamVolProc.running = true
                            }
                        }
                    }
                }
            }
        }

        Item { implicitHeight: 4 }
    }
}
