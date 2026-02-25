import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
  id: topPopup

  // PanelWindow anchors: boolean only in 0.2.1
  anchors {
    top: true
    left: true
    right: true
  }

  color: "transparent"
  implicitHeight: 560

  signal closeRequested()

  // dark theme
  property color panel: "#151515"
  property color bg: "#0f0f0f"
  property color border: "#2a2a2a"
  property color text: "#f2f2f2"
  property color subtext: "#a8a8a8"
  property color accent2: "#9f7cff"

  property int radiusOuter: 18
  property int activeTab: 0 // 0 Dashboard, 1 Media, 2 Performance, 3 Workspaces

  Process { id: runner }
  Process { id: perfPoll }
  Process { id: mprisPoll }
  Process { id: mprisCtl }

  property var now: new Date()
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: topPopup.now = new Date()
  }

  // Media state
  property bool hasPlayer: false
  property string playerName: ""
  property string trackTitle: ""
  property string trackArtist: ""
  property bool playing: false
  property string artUrl: ""

  // Performance state
  property string gpuTemp: "--"
  property string cpuTemp: "--"
  property string memUsed: "--"
  property string memTotal: "--"

  function sh(cmd) {
    if (!cmd || cmd.length === 0) return;
    runner.exec({ command: [ "sh", "-lc", cmd ] });
  }

  function refreshMpris() {
    mprisPoll.exec({
      command: [ "sh", "-lc",
        "P=$(" +
          "playerctl -a status --format '{{playerName}}|{{status}}' 2>/dev/null " +
          "| awk -F'|' '$2==\"Playing\"{print $1; exit}'" +
        "); " +
        "if [ -z \"$P\" ]; then P=$(playerctl -l 2>/dev/null | grep -i spotify | head -n1); fi; " +
        "if [ -z \"$P\" ]; then P=$(playerctl -l 2>/dev/null | head -n1); fi; " +
        "if [ -z \"$P\" ]; then exit 0; fi; " +
        "playerctl -p \"$P\" metadata --format '{{playerName}}|{{status}}|{{artist}}|{{title}}|{{mpris:artUrl}}' 2>/dev/null || true"
      ]
    });
  }

  function mpris(cmd) {
    if (!cmd || cmd.length === 0) return;
    mprisCtl.exec({ command: [ "sh", "-lc", "playerctl " + cmd + " 2>/dev/null || true" ] });
  }

  function refreshPerf() {
    perfPoll.exec({
      command: [ "sh", "-lc",
        "CPU=$(sensors 2>/dev/null | awk '/Package id 0:|Tctl:|CPU Temperature:/{gsub(/[+°C]/,\"\"); print $2; exit}'); " +
        "GPU=$(sensors 2>/dev/null | awk '/edge:/{gsub(/[+°C]/,\"\"); print $2; exit}'); " +
        "MEM=$(free -m | awk '/Mem:/ {print $3\"|\"$2}'); " +
        "echo \"${CPU:-}||${GPU:-}||${MEM:-}\""
      ]
    });
  }

  Timer {
    interval: 1200
    running: true
    repeat: true
    onTriggered: {
      refreshMpris()
      refreshPerf()
    }
  }

  Connections {
    target: mprisPoll
    function onFinished(exitCode, stdout, stderr) {
      const out = String(stdout || "").trim();
      if (!out) {
        topPopup.hasPlayer = false
        topPopup.playerName = ""
        topPopup.trackArtist = ""
        topPopup.trackTitle = ""
        topPopup.playing = false
        topPopup.artUrl = ""
        return
      }
      const parts = out.split("|")
      topPopup.playerName = parts[0] || ""
      const status = (parts[1] || "").toLowerCase()
      topPopup.playing = (status === "playing")
      topPopup.trackArtist = parts[2] || ""
      topPopup.trackTitle = parts[3] || ""
      topPopup.artUrl = parts[4] || ""
      topPopup.hasPlayer = topPopup.playerName.length > 0
    }
  }

  Connections {
    target: perfPoll
    function onFinished(exitCode, stdout, stderr) {
      const out = String(stdout || "").trim()
      const parts = out.split("||")
      const cpu = (parts[0] || "").trim()
      const gpu = (parts[1] || "").trim()
      const mem = (parts[2] || "").trim()

      topPopup.cpuTemp = cpu && cpu.length ? cpu : "--"
      topPopup.gpuTemp = gpu && gpu.length ? gpu : "--"

      if (mem.includes("|")) {
        const m = mem.split("|")
        topPopup.memUsed = (m[0] || "--").trim()
        topPopup.memTotal = (m[1] || "--").trim()
      } else {
        topPopup.memUsed = "--"
        topPopup.memTotal = "--"
      }
    }
  }

  // Overlay fills the full window; "card" is positioned with normal QtQuick margins
  Item {
    anchors.fill: parent

    Item {
      id: cardHost
      width: 900
      height: 520
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 12

      Item {
        id: body
        anchors.fill: parent

        Rectangle {
          anchors.fill: parent
          radius: topPopup.radiusOuter
          color: topPopup.panel
          border.color: topPopup.border
          border.width: 1
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
          Layout.fillWidth: true
          spacing: 14

          component TabBtn: Item {
            id: t
            property string label: ""
            property int tabIndex: 0
            property bool active: topPopup.activeTab === tabIndex
            signal clicked()

            width: 160
            height: 38

            Rectangle {
              anchors.fill: parent
              radius: 12
              color: topPopup.bg
              border.color: t.active ? topPopup.accent2 : topPopup.border
              border.width: 1
              opacity: t.active ? 1.0 : 0.92
            }

            Text {
              anchors.centerIn: parent
              text: t.label
              color: t.active ? topPopup.text : topPopup.subtext
              font.pixelSize: 12
              font.weight: 700
            }

            MouseArea { anchors.fill: parent; onClicked: t.clicked() }
          }

          TabBtn { label: "Dashboard"; tabIndex: 0; onClicked: topPopup.activeTab = 0 }
          TabBtn { label: "Media"; tabIndex: 1; onClicked: topPopup.activeTab = 1 }
          TabBtn { label: "Performance"; tabIndex: 2; onClicked: topPopup.activeTab = 2 }
          TabBtn { label: "Workspaces"; tabIndex: 3; onClicked: topPopup.activeTab = 3 }

          Item { Layout.fillWidth: true }

          Rectangle {
            width: 42
            height: 38
            radius: 12
            color: topPopup.bg
            border.color: topPopup.border
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "×"
              color: topPopup.subtext
              font.pixelSize: 18
              font.weight: 800
            }

            MouseArea { anchors.fill: parent; onClicked: topPopup.closeRequested() }
          }
        }

        StackLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          currentIndex: topPopup.activeTab

          // Dashboard
          Item {
            ColumnLayout {
              anchors.fill: parent
              spacing: 12

              Rectangle {
                Layout.fillWidth: true
                height: 110
                radius: 16
                color: topPopup.bg
                border.color: topPopup.border
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 14
                  spacing: 14

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: "Quick"; color: topPopup.text; font.pixelSize: 14; font.weight: 800 }
                    Text {
                      text: "Date: " + Qt.formatDateTime(topPopup.now, "dd.MM.yyyy") + "  •  Time: " + Qt.formatDateTime(topPopup.now, "HH:mm")
                      color: topPopup.subtext
                      font.pixelSize: 11
                    }
                  }

                  Rectangle {
                    width: 140
                    height: 82
                    radius: 14
                    color: "#141414"
                    border.color: topPopup.border
                    border.width: 1

                    Column {
                      anchors.centerIn: parent
                      spacing: 6
                      Text { text: "Launcher"; color: topPopup.text; font.pixelSize: 12; font.weight: 800; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                      Text { text: "rofi -show drun"; color: topPopup.subtext; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                    }

                    MouseArea { anchors.fill: parent; onClicked: topPopup.sh("rofi -show drun") }
                  }
                }
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: topPopup.bg
                border.color: topPopup.border
                border.width: 1

                Column {
                  anchors.fill: parent
                  anchors.margins: 14
                  spacing: 10

                  Text { text: "Tip"; color: topPopup.text; font.pixelSize: 13; font.weight: 800 }
                  Text {
                    text: "Wenn es optisch nicht passt: Icons/Fonts/Wallpaper-Contrast sind meist die Ursache."
                    wrapMode: Text.WordWrap
                    color: topPopup.subtext
                    font.pixelSize: 11
                  }
                }
              }
            }
          }

          // Media
          Item {
            Text {
              anchors.centerIn: parent
              text: topPopup.hasPlayer ? (topPopup.trackTitle.length ? topPopup.trackTitle : topPopup.playerName) : "No player"
              color: topPopup.text
              font.pixelSize: 14
              font.weight: 800
            }
          }

          // Performance
          Item {
            Text {
              anchors.centerIn: parent
              text: "CPU: " + topPopup.cpuTemp + "°C  •  GPU: " + topPopup.gpuTemp + "°C  •  RAM: " + topPopup.memUsed + "/" + topPopup.memTotal + " MiB"
              color: topPopup.subtext
              font.pixelSize: 12
            }
          }

          // Workspaces
          Item {
            Text {
              anchors.centerIn: parent
              text: Hyprland.focusedWorkspace ? ("Workspace " + Hyprland.focusedWorkspace.id) : "Workspace --"
              color: topPopup.subtext
              font.pixelSize: 12
            }
          }
        }
      }
    }
  }

  // IMPORTANT: mask belongs on PanelWindow (works like in Sidebar.qml)
  mask: Region { item: body }
}
