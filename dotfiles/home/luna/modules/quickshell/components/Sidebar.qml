import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
  id: sidebar
  anchors { top: true; bottom: true; left: true }
  implicitWidth: 52
  color: "transparent"

  signal toggleTopPopup()
  signal requestTopTab(int idx)

  // Dark theme
  property color panel: "#151515"
  property color bg: "#0f0f0f"
  property color border: "#2a2a2a"
  property color text: "#f2f2f2"
  property color subtext: "#a8a8a8"
  property color accent: "#ffffff"
  property color accent2: "#9f7cff"
  property color danger: "#ffffff"

  property int radiusOuter: 18
  property int leftSquareStrip: 18
  property int activeIndex: 0

  // time updates
  property var now: new Date()
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: sidebar.now = new Date()
  }

  // processes
  Process { id: runner }
  Process { id: mprisPoll }
  Process { id: mprisCtl }

  property bool hasPlayer: false
  property string playerName: ""
  property string trackTitle: ""
  property string trackArtist: ""
  property bool playing: false
  property string artUrl: ""

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

  Timer {
    interval: 1200
    running: true
    repeat: true
    onTriggered: refreshMpris()
  }

  Connections {
    target: mprisPoll
    function onFinished(exitCode, stdout, stderr) {
      const out = String(stdout || "").trim();
      if (!out || out.length === 0) {
        sidebar.hasPlayer = false
        sidebar.playerName = ""
        sidebar.trackArtist = ""
        sidebar.trackTitle = ""
        sidebar.playing = false
        sidebar.artUrl = ""
        return
      }
      const parts = out.split("|")
      sidebar.playerName = parts[0] || ""
      const status = (parts[1] || "").toLowerCase()
      sidebar.playing = (status === "playing")
      sidebar.trackArtist = parts[2] || ""
      sidebar.trackTitle = parts[3] || ""
      sidebar.artUrl = parts[4] || ""
      sidebar.hasPlayer = sidebar.playerName.length > 0
    }
  }

  function asset(name) {
    // Sidebar.qml is in components/, assets/ is sibling of components/
    return Qt.resolvedUrl("../assets/" + name);
  }

  // sidebar buttons (these can open popup tabs similar to video)
  // 0 Dashboard, 1 Media, 2 Performance, 3 Workspaces
  property var topTabs: [
    { icon: "menu.svg", tip: "Dashboard", tab: 0 },
    { icon: "play.svg", tip: "Media", tab: 1 },
    { icon: "cpu.svg", tip: "Performance", tab: 2 },
    { icon: "workspaces.svg", tip: "Workspaces", tab: 3 }
  ]

  // nav with custom icons (launchers)
  property var navItems: [
    { icon: "apps.svg", tip: "Apps", cmd: "rofi -show drun" },
    { icon: "search.svg", tip: "Search", cmd: "rofi -show drun" },
    { icon: "browser.svg", tip: "Browser", cmd: "zen-browser" },
    { icon: "terminal.svg", tip: "Terminal", cmd: "ghostty" },
    { icon: "files.svg", tip: "Files", cmd: "nautilus" }
  ]

  Item {
    id: body
    anchors.fill: parent

    Rectangle {
      anchors.fill: parent
      radius: sidebar.radiusOuter
      color: sidebar.panel
      border.color: sidebar.border
      border.width: 1
    }

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: sidebar.leftSquareStrip
      color: sidebar.panel
    }

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 1
      color: sidebar.border
    }
  }

  mask: Region { item: body }

  component IconButton : Item {
    id: root
    property string tip: ""
    property string iconFile: ""
    property bool active: false
    property bool small: false
    signal clicked()

    width: small ? 38 : 40
    height: small ? 38 : 40

    property bool hovered: false
    property bool pressed: false

    Rectangle {
      anchors.fill: parent
      radius: 16
      color: sidebar.bg
      border.color: root.active ? sidebar.accent2 : sidebar.border
      border.width: 1
      opacity: root.hovered ? 1.0 : 0.96
      scale: root.pressed ? 0.96 : (root.hovered ? 1.03 : 1.0)
      Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 140 } }
      Behavior on border.color { ColorAnimation { duration: 160 } }
    }

    Image {
      anchors.centerIn: parent
      width: small ? 18 : 20
      height: small ? 18 : 20
      source: asset(root.iconFile)
      smooth: true
      opacity: 0.95
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      onEntered: root.hovered = true
      onExited: { root.hovered = false; root.pressed = false }
      onPressed: root.pressed = true
      onReleased: root.pressed = false
      onClicked: root.clicked()
    }

    ToolTip.visible: root.hovered
    ToolTip.text: root.tip
    ToolTip.delay: 320
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 10

    // Top popup shortcuts like the video tabs
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      Repeater {
        model: sidebar.topTabs.length
        delegate: IconButton {
          required property int index
          tip: sidebar.topTabs[index].tip
          iconFile: sidebar.topTabs[index].icon
          active: false
          onClicked: {
            sidebar.requestTopTab(sidebar.topTabs[index].tab)
          }
        }
      }
    }

    // nav buttons
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      Repeater {
        model: sidebar.navItems.length
        delegate: IconButton {
          required property int index
          tip: sidebar.navItems[index].tip
          iconFile: sidebar.navItems[index].icon
          active: sidebar.activeIndex === index
          onClicked: {
            sidebar.activeIndex = index
            sh(sidebar.navItems[index].cmd + " & disown")
          }
        }
      }
    }

    Item { Layout.fillHeight: true }

    // quick actions
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      IconButton {
        small: true
        tip: "WiFi"
        iconFile: "wifi.svg"
        onClicked: sh("nm-applet & disown")
      }

      IconButton {
        small: true
        tip: "Bluetooth"
        iconFile: "bluetooth.svg"
        onClicked: sh("blueman-manager & disown")
      }

      IconButton {
        small: true
        tip: "Sound"
        iconFile: "sound.svg"
        onClicked: sh("pavucontrol & disown")
      }

      IconButton {
        small: true
        tip: "Power"
        iconFile: "power.svg"
        onClicked: sh("wlogout & disown")
      }
    }

    // workspace dots
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 7

      Repeater {
        model: 10
        delegate: Rectangle {
          required property int index
          width: 9; height: 9
          radius: 5
          property int ws: index + 1
          property bool isActive: Hyprland.focusedWorkspace && (Hyprland.focusedWorkspace.id === ws)

          color: isActive ? sidebar.accent2 : sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: isActive ? 1.0 : 0.40

          Behavior on opacity { NumberAnimation { duration: 140 } }
          Behavior on color { ColorAnimation { duration: 160 } }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: Hyprland.dispatch("workspace " + ws)
          }
        }
      }
    }

    // Mini player (always visible)
    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      width: 40
      height: 108
      radius: 16
      color: sidebar.bg
      border.color: sidebar.border
      border.width: 1
      clip: true

      property bool hovered: false
      opacity: hovered ? 1.0 : 0.92
      Behavior on opacity { NumberAnimation { duration: 160 } }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: parent.hovered = true
        onExited: parent.hovered = false
        onClicked: sidebar.requestTopTab(1) // Media tab
      }

      Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        Text {
          text: sidebar.hasPlayer
            ? (sidebar.trackTitle && sidebar.trackTitle.length > 0 ? sidebar.trackTitle : sidebar.playerName)
            : "No player"
          color: sidebar.text
          font.pixelSize: 10
          font.weight: 700
          elide: Text.ElideRight
        }

        Text {
          visible: sidebar.hasPlayer && sidebar.trackArtist && sidebar.trackArtist.length > 0
          text: sidebar.trackArtist
          color: sidebar.subtext
          font.pixelSize: 9
          elide: Text.ElideRight
        }

        Row {
          spacing: 6

          IconButton {
            small: true
            tip: "Prev"
            iconFile: "prev.svg"
            onClicked: mpris("previous")
          }

          IconButton {
            small: true
            tip: sidebar.playing ? "Pause" : "Play"
            iconFile: sidebar.playing ? "pause.svg" : "play.svg"
            onClicked: mpris("play-pause")
          }

          IconButton {
            small: true
            tip: "Next"
            iconFile: "next.svg"
            onClicked: mpris("next")
          }
        }
      }
    }

    // bottom label + time
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      Item {
        width: 40
        height: 70
        Text {
          anchors.centerIn: parent
          rotation: 90
          text: "Desktop"
          color: sidebar.subtext
          font.pixelSize: 11
          font.weight: 700
        }
      }

      Item {
        width: 40
        height: 86

        Column {
          anchors.centerIn: parent
          spacing: 5

          Text {
            text: Qt.formatDateTime(sidebar.now, "dd")
            color: sidebar.text
            font.pixelSize: 13
            width: 40
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            text: Qt.formatDateTime(sidebar.now, "MM")
            color: sidebar.subtext
            font.pixelSize: 10
            width: 40
            horizontalAlignment: Text.AlignHCenter
          }

          Rectangle {
            width: 16; height: 1
            radius: 1
            color: sidebar.border
            anchors.horizontalCenter: parent.horizontalCenter
          }

          Text {
            text: Qt.formatDateTime(sidebar.now, "HH")
            color: sidebar.text
            font.pixelSize: 12
            width: 40
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            text: Qt.formatDateTime(sidebar.now, "mm")
            color: sidebar.subtext
            font.pixelSize: 10
            width: 40
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }
}
