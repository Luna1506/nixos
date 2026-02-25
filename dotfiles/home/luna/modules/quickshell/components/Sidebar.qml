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

  // ---- theme (dark grey, not bluish) ----
  property color bg: "#111111"
  property color panel: "#171717"
  property color border: "#2b2b2b"
  property color text: "#f0f0f0"
  property color subtext: "#a6a6a6"
  property color accent: "#d9d9d9"
  property color accent2: "#8b5cf6" // tiny sparkle for active states, not "blue"
  property color danger: "#ffffff"  // power icon should be white

  // thinner / shape
  property int radiusOuter: 18  // right side rounding
  property int leftSquareStrip: 18

  // active highlight
  property int activeIndex: 0

  // time state (so it really updates)
  property var now: new Date()

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: sidebar.now = new Date()
  }

  // ---- processes ----
  Process { id: runner }
  Process { id: nmproc }
  Process { id: btproc }

  Process { id: mprisPoll }
  Process { id: mprisCtl }

  property bool wifiOn: false
  property int wifiStrength: 0
  property string wifiName: ""
  property bool btOn: false

  // ---- mpris (spotify/playerctl) ----
  property bool hasPlayer: false
  property string playerName: ""
  property string trackTitle: ""
  property string trackArtist: ""
  property bool playing: false

  function sh(cmd) {
    if (!cmd || cmd.length === 0) return;
    runner.exec({ command: [ "sh", "-lc", cmd ] });
  }

  function refreshWifi() {
    nmproc.exec({ command: [ "sh", "-lc", "nmcli -t -f WIFI g 2>/dev/null || true" ] });
  }
  function refreshWifiDetails() {
    nmproc.exec({ command: [ "sh", "-lc", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | awk -F: '$1==\"yes\"{print $2\":\"$3; exit}' 2>/dev/null || true" ] });
  }
  function refreshBt() {
    btproc.exec({ command: [ "sh", "-lc", "bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}' || true" ] });
  }

  function refreshMpris() {
    // playerctl might return nothing if no player
    // Format: player|status|artist|title
    mprisPoll.exec({
      command: [ "sh", "-lc",
        "playerctl -a metadata --format '{{playerName}}|{{status}}|{{artist}}|{{title}}' 2>/dev/null | head -n1 || true"
      ]
    });
  }

  function mpris(cmd) {
    if (!cmd || cmd.length === 0) return;
    mprisCtl.exec({ command: [ "sh", "-lc", "playerctl " + cmd + " 2>/dev/null || true" ] });
  }

  Timer {
    interval: 2500
    running: true
    repeat: true
    onTriggered: {
      refreshWifi()
      refreshWifiDetails()
      refreshBt()
      refreshMpris()
    }
  }

  Connections {
    target: nmproc
    function onFinished(exitCode, stdout, stderr) {
      const out = String(stdout || "").trim();

      if (out === "enabled" || out === "disabled") {
        sidebar.wifiOn = (out === "enabled");
        return;
      }

      if (out.includes(":")) {
        const parts = out.split(":");
        sidebar.wifiName = parts[0] || "";
        const sig = parseInt(parts[1] || "0", 10);
        sidebar.wifiStrength = isNaN(sig) ? 0 : sig;
      }
    }
  }

  Connections {
    target: btproc
    function onFinished(exitCode, stdout, stderr) {
      const out = String(stdout || "").trim().toLowerCase();
      sidebar.btOn = (out === "yes" || out === "true" || out === "on");
    }
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
        return
      }

      const parts = out.split("|")
      sidebar.playerName = parts[0] || ""
      const status = (parts[1] || "").toLowerCase()
      sidebar.playing = (status === "playing")
      sidebar.trackArtist = parts[2] || ""
      sidebar.trackTitle = parts[3] || ""
      sidebar.hasPlayer = sidebar.playerName.length > 0
    }
  }

  function iconOrEmpty(name) {
    const p = Quickshell.iconPath(name);
    return p ? p : "";
  }

  // ---- buttons like video-ish: big nav + quick toggles ----
  // (You can replace icons later with a pinned SVG icon pack for 1:1 look)
  property var navItems: [
    { icon: "view-app-grid", tip: "Apps", cmd: "rofi -show drun" },
    { icon: "system-search", tip: "Search", cmd: "rofi -show drun" },
    { icon: "internet-web-browser", tip: "Browser", cmd: "firefox" },
    { icon: "utilities-terminal", tip: "Terminal", cmd: "ghostty" },
    { icon: "system-file-manager", tip: "Files", cmd: "nautilus" },
    { icon: "preferences-system", tip: "Settings", cmd: "" }
  ]

  // ---- panel body: left square, right rounded ----
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

  // Ensure click area is exactly the panel region
  mask: Region { item: body }

  // ---- animations helpers ----
  component ClickButton : Item {
    id: root
    property string tip: ""
    property string iconName: ""
    property string fallbackText: ""
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
      color: root.active ? sidebar.accent : sidebar.bg
      border.color: root.active ? sidebar.accent : sidebar.border
      border.width: 1
      opacity: root.hovered ? 1.0 : 0.96

      // subtle lift
      scale: root.pressed ? 0.96 : (root.hovered ? 1.03 : 1.0)
      Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    Item {
      anchors.centerIn: parent
      width: small ? 18 : 20
      height: small ? 18 : 20

      Image {
        anchors.fill: parent
        source: sidebar.iconOrEmpty(root.iconName)
        visible: source !== ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: 0.95
      }

      Text {
        anchors.centerIn: parent
        visible: sidebar.iconOrEmpty(root.iconName) === ""
        text: root.fallbackText && root.fallbackText.length > 0 ? root.fallbackText : "?"
        color: sidebar.text
        font.pixelSize: small ? 10 : 11
        font.weight: 800
      }
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

  // ---- layout ----
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 10

    // top profile circle
    Item {
      Layout.alignment: Qt.AlignHCenter
      width: 40; height: 40

      Rectangle {
        anchors.fill: parent
        radius: 20
        color: sidebar.bg
        border.color: sidebar.border
        border.width: 1
      }

      Text {
        anchors.centerIn: parent
        text: "A"
        color: sidebar.text
        font.pixelSize: 14
        font.weight: 800
      }
    }

    // nav buttons
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      Repeater {
        model: sidebar.navItems.length
        delegate: ClickButton {
          required property int index
          tip: sidebar.navItems[index].tip
          iconName: sidebar.navItems[index].icon
          fallbackText: tip.length > 0 ? tip[0].toUpperCase() : "?"
          active: sidebar.activeIndex === index

          onClicked: {
            sidebar.activeIndex = index
            const cmd = sidebar.navItems[index].cmd
            if (cmd && cmd.length > 0) sidebar.sh(cmd)
          }
        }
      }
    }

    // spacer
    Item { Layout.fillHeight: true }

    // quick controls group (wifi / bt / sound / power)
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      // WiFi -> nm-applet
      ClickButton {
        tip: sidebar.wifiOn ? ("WiFi: " + (sidebar.wifiName || "connected") + " (" + sidebar.wifiStrength + "%)") : "WiFi"
        iconName: "network-wireless"
        fallbackText: sidebar.wifiOn ? "W" : "x"
        small: true
        onClicked: sidebar.sh("nm-applet & disown")
      }

      // Bluetooth -> blueman-manager
      ClickButton {
        tip: sidebar.btOn ? "Bluetooth (blueman)" : "Bluetooth (blueman)"
        iconName: "bluetooth"
        fallbackText: "B"
        small: true
        onClicked: sidebar.sh("blueman-manager & disown")
      }

      // Sound -> pavucontrol
      ClickButton {
        tip: "Sound (pavucontrol)"
        iconName: "audio-volume-high"
        fallbackText: "S"
        small: true
        onClicked: sidebar.sh("pavucontrol & disown")
      }

      // Power -> wlogout (white)
      Item {
        width: 38; height: 38
        property bool hovered: false
        property bool pressed: false

        Rectangle {
          anchors.fill: parent
          radius: 16
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: parent.hovered ? 1.0 : 0.96
          scale: parent.pressed ? 0.96 : (parent.hovered ? 1.03 : 1.0)
          Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        Text {
          anchors.centerIn: parent
          text: "⏻"
          color: sidebar.danger
          font.pixelSize: 17
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          onEntered: parent.hovered = true
          onExited: { parent.hovered = false; parent.pressed = false }
          onPressed: parent.pressed = true
          onReleased: parent.pressed = false
          onClicked: sidebar.sh("wlogout & disown")
        }
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

    // Spotify mini player (animated slide in/out like video-ish)
    Item {
      Layout.alignment: Qt.AlignHCenter
      width: 40
      height: sidebar.hasPlayer ? 110 : 24

      property bool hovered: false

      // collapsed indicator
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 10
        height: 10
        radius: 5
        y: 6
        color: sidebar.hasPlayer ? (sidebar.playing ? sidebar.accent2 : sidebar.subtext) : sidebar.border
        opacity: sidebar.hasPlayer ? 0.9 : 0.45
      }

      Rectangle {
        id: mini
        anchors.horizontalCenter: parent.horizontalCenter
        y: 20
        width: 40
        height: sidebar.hasPlayer ? 90 : 0
        radius: 16
        color: sidebar.bg
        border.color: sidebar.border
        border.width: 1
        clip: true

        // animate open/close
        opacity: sidebar.hasPlayer ? (parent.hovered ? 1.0 : 0.92) : 0.0
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Column {
          anchors.fill: parent
          anchors.margins: 6
          spacing: 6

          Text {
            text: sidebar.trackTitle && sidebar.trackTitle.length > 0 ? sidebar.trackTitle : (sidebar.playerName || "Player")
            color: sidebar.text
            font.pixelSize: 10
            font.weight: 700
            elide: Text.ElideRight
          }

          Text {
            text: sidebar.trackArtist
            visible: sidebar.trackArtist && sidebar.trackArtist.length > 0
            color: sidebar.subtext
            font.pixelSize: 9
            elide: Text.ElideRight
          }

          Row {
            spacing: 6

            ClickButton {
              small: true
              tip: "Prev"
              iconName: "media-skip-backward"
              fallbackText: "⟨"
              onClicked: sidebar.mpris("previous")
            }

            ClickButton {
              small: true
              tip: sidebar.playing ? "Pause" : "Play"
              iconName: sidebar.playing ? "media-playback-pause" : "media-playback-start"
              fallbackText: sidebar.playing ? "||" : "▶"
              onClicked: sidebar.mpris("play-pause")
            }

            ClickButton {
              small: true
              tip: "Next"
              iconName: "media-skip-forward"
              fallbackText: "⟩"
              onClicked: sidebar.mpris("next")
            }
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: parent.hovered = true
        onExited: parent.hovered = false
        // also allow click to toggle play/pause when hovering mini area
        onClicked: {
          if (sidebar.hasPlayer) sidebar.mpris("play-pause")
        }
      }
    }

    // bottom: label + time
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      Item {
        width: 40
        height: 92
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
