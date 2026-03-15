// ─── PlayerTab.qml ────────────────────────────────────────────────────────────
// Tab 2: Media player via playerctl.
// Polls playerctl every 2 s while the panel is visible.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    required property var panel

    implicitHeight: col.implicitHeight + 8

    // ── State ──────────────────────────────────────────────────────────────────
    property string trackTitle:  "Nothing playing"
    property string trackArtist: ""
    property string trackAlbum:  ""
    property bool   isPlaying:   false
    property int    volume:      100     // 0–100
    property string playerName:  ""

    // ── Refresh (every 2 s) ────────────────────────────────────────────────────
    Timer {
        interval:         2000
        repeat:           true
        running:          true
        triggeredOnStart: true
        onTriggered:      {
            statusProc.running = false
            statusProc.running = true
        }
    }

    // ── playerctl status + metadata ────────────────────────────────────────────
    Process {
        id: statusProc
        // Output format:  STATUS\nTITLE\nARTIST\nALBUM\nPLAYER
        command: ["sh", "-c", [
            "STATUS=$(playerctl status 2>/dev/null)",
            "TITLE=$(playerctl metadata title 2>/dev/null)",
            "ARTIST=$(playerctl metadata artist 2>/dev/null)",
            "ALBUM=$(playerctl metadata album 2>/dev/null)",
            "PLAYER=$(playerctl -l 2>/dev/null | head -1)",
            "printf '%s\\n%s\\n%s\\n%s\\n%s\\n' \"$STATUS\" \"$TITLE\" \"$ARTIST\" \"$ALBUM\" \"$PLAYER\""
        ].join("; ")]
        running: false

        // Collect all lines into an array, then parse on complete
        property var lines: []

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                statusProc.lines.push(line)
            }
        }

        onRunningChanged: {
            if (!running && lines.length >= 4) {
                var status = lines[0].trim()
                root.isPlaying    = (status === "Playing")
                root.trackTitle   = lines[1].trim() || "Nothing playing"
                root.trackArtist  = lines[2].trim()
                root.trackAlbum   = lines[3].trim()
                root.playerName   = lines.length >= 5 ? lines[4].trim() : ""
                lines = []
            } else if (running) {
                lines = []
            }
        }
    }

    // ── playerctl command runner (fire-and-forget) ────────────────────────────
    Process {
        id: cmdProc
        running: false
        onRunningChanged: {
            if (!running) {
                // Small delay so playerctl can propagate before we re-read
                refreshDelay.restart()
            }
        }
    }

    // Volume: separate process – avoids stomping cmdProc
    Process {
        id: volProc
        running: false
    }

    Timer {
        id: refreshDelay
        interval: 300
        repeat:   false
        onTriggered: {
            statusProc.running = false
            statusProc.running = true
        }
    }

    function runCmd(cmd) {
        cmdProc.command = ["playerctl", cmd]
        cmdProc.running = false
        cmdProc.running = true
    }

    // ── UI ─────────────────────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right }
        spacing: 8

        // ── Track info card ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   80
            color:            panel.cSurface
            radius:           10

            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  14
                    rightMargin: 14
                }
                spacing: 12

                // Placeholder album art
                Rectangle {
                    width:  52
                    height: 52
                    radius: 6
                    color:  panel.cOverlay

                    Text {
                        anchors.centerIn: parent
                        text:             ""
                        font.pixelSize:   24
                        color:            panel.cSubtext
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text:             root.trackTitle
                        font.pixelSize:   14
                        font.weight:      Font.SemiBold
                        color:            panel.cText
                        elide:            Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text:             root.trackArtist || (root.playerName.length > 0
                                              ? root.playerName : " ")
                        font.pixelSize:   12
                        color:            panel.cSubtext
                        elide:            Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text:             root.trackAlbum
                        font.pixelSize:   11
                        color:            panel.cOverlay
                        elide:            Text.ElideRight
                        visible:          root.trackAlbum.length > 0
                    }
                }
            }
        }

        // ── Playback controls ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   56
            color:            panel.cSurface
            radius:           10

            RowLayout {
                anchors.centerIn: parent
                spacing:          8

                // Previous
                CtrlButton {
                    panel:  root.panel
                    iconText:   ""
                    onClicked: root.runCmd("previous")
                }

                // Play / Pause
                CtrlButton {
                    panel:     root.panel
                    iconText:      root.isPlaying ? "" : ""
                    accent:    true
                    iconSize:  22
                    onClicked: root.runCmd("play-pause")
                }

                // Next
                CtrlButton {
                    panel:  root.panel
                    iconText:   ""
                    onClicked: root.runCmd("next")
                }

                // ── Divider ────────────────────────────────────────────────────
                Rectangle {
                    width:  1
                    height: 24
                    color:  panel.cOverlay
                }

                // Stop
                CtrlButton {
                    panel:  root.panel
                    iconText:   ""
                    onClicked: root.runCmd("stop")
                }
            }
        }

        // ── Volume row ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   44
            color:            panel.cSurface
            radius:           10

            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  14
                    rightMargin: 14
                }
                spacing: 10

                Text {
                    text:           ""
                    font.pixelSize: 14
                    color:          panel.cSubtext
                }

                Slider {
                    id: volSlider
                    Layout.fillWidth: true
                    from:  0
                    to:    100
                    value: root.volume
                    stepSize: 1

                    background: Rectangle {
                        x:      volSlider.leftPadding
                        y:      volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        width:  volSlider.availableWidth
                        height: 4
                        radius: 2
                        color:  panel.cOverlay

                        Rectangle {
                            width:  volSlider.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color:  panel.cAccent
                        }
                    }

                    handle: Rectangle {
                        x:      volSlider.leftPadding + volSlider.visualPosition
                                    * (volSlider.availableWidth - width)
                        y:      volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        width:  14
                        height: 14
                        radius: 7
                        color:  panel.cText
                    }

                    onMoved: {
                        root.volume = value
                        // Use the pre-declared volProc (can't instantiate QML types in JS)
                        var v = (value / 100).toFixed(2)
                        volProc.command = ["playerctl", "volume", v]
                        volProc.running = false
                        volProc.running = true
                    }
                }

                Text {
                    text:           root.volume + "%"
                    font.pixelSize: 12
                    color:          panel.cSubtext
                    Layout.minimumWidth: 32
                }
            }
        }

        Item { implicitHeight: 4 }
    }
}
