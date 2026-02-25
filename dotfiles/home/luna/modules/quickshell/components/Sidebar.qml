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

  // ---- theme (dark grey) ----
  property color bg: "#111111"
  property color panel: "#171717"
  property color border: "#2b2b2b"
  property color text: "#f0f0f0"
  property color subtext: "#a6a6a6"
  property color accent: "#d9d9d9"
  property color accent2: "#8b5cf6" // tiny sparkle for active
  property color danger: "#ffffff"  // power icon white

  property int radiusOuter: 18
  property int leftSquareStrip: 18

  property int activeIndex: 0

  // time must be stateful to update
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

  // ---- mpris ----
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
    // prefer spotify if it exists, else first available
    // output: player|status|artist|title
    mprisPoll.exec({
      command: [ "sh", "-lc",
        "playerctl -l 2>/dev/null | grep -i spotify | head -n1 | xargs -r -I{} playerctl -p {} metadata --format '{{playerName}}|{{status}}|{{artist}}|{{title}}' 2>/dev/null || " +
        "playerctl -a metadata --format '{{playerName}}|{{status}}|{{artist}}|{{title}}' 2>/dev/null | head -n1 || true"
      ]
    });
  }

  function mpris(cmd) {
    if (!cmd || cmd.length === 0) return;
    mprisCtl.exec({ command: [ "sh", "-lc", "playerctl " + cmd + " 2>/dev/null || true" ] });
  }

  Timer {
    interval: 1500
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

  // --- nav items ---
  property var navItems: [
    { icon: "view-app-grid", tip: "Apps", cmd: "rofi -show drun" },
    { icon: "system-search", tip: "Search", cmd: "rofi -show drun" },
    { icon: "internet-web-browser", tip: "Browser", cmd: "command -v zen-browser >/dev/null && zen-browser || command -v zen >/dev/null && zen || zen-browser" },
    { icon: "utilities-terminal", tip: "Terminal", cmd: "ghostty" },
    { icon: "system-file-manager", tip: "Files", cmd: "nautilus" }
  ]

  // ---- panel body ----
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

  // ---- reusable button ----
  component ClickButton : Item {
    id: root
    property string tip: ""
    property string iconName: ""
    property string fallbackText: ""
    property bool active: false
    property bool small: false
    property color iconColor: sidebar.text
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
        color: root.iconColor
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

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 10

    // TOP: no more "A" — just an app/menu button
    ClickButton {
      Layout.alignment: Qt.AlignHCenter
      tip: "Menu"
      iconName: "open-menu-symbolic"
      fallbackText: "≡"
      onClicked: sidebar.sh("rofi -show drun")
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

    Item { Layout.fillHeight: true }

    // quick controls (launch apps)
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      ClickButton {
        small: true
        tip: "WiFi (nm-applet)"
        iconName: "network-wireless"
        fallbackText: "W"
        onClicked: sidebar.sh("nm-applet & disown")
      }

      ClickButton {
        small: true
        tip: "Bluetooth (blueman)"
        iconName: "bluetooth"
        fallbackText: "B"
        onClicked: sidebar.sh("blueman-manager & disown")
      }

      ClickButton {
        small: true
        tip: "Sound (pavucontrol)"
        iconName: "audio-volume-high"
        fallbackText: "S"
        onClicked: sidebar.sh("pavucontrol & disown")
      }

      ClickButton {
        small: true
        tip: "Power (wlogout)"
        iconName: "system-shutdown"
        fallbackText: "⏻"
        iconColor: sidebar.danger
        onClicked: sidebar.sh("wlogout & disown")
      }
    }

    // workspaces
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

    // --- ALWAYS visible mini player (shows "No player" if none) ---
    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      width: 40
      height: 108
      radius: 16
      color: sidebar.bg
      border.color: sidebar.border
      border.width: 1
      clip: true

      // subtle hover anim
      property bool hovered: false
      opacity: hovered ? 1.0 : 0.92
      Behavior on opacity { NumberAnimation { duration: 160 } }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: parent.hovered = true
        onExited: parent.hovered = false
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

    // bottom: label + time
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
