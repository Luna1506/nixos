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
  property color accent2: "#8b5cf6" // small highlight
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
    nmproc.exec({ command: [ "sh", "-lc",
      "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | awk -F: '$1==\"yes\"{print $2\":\"$3; exit}' 2>/dev/null || true"
    ]});
  }
  function refreshBt() {
    btproc.exec({ command: [ "sh", "-lc",
      "bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}' || true"
    ]});
  }

  // Choose the *playing* player first; else prefer spotify; else first available.
  function refreshMpris() {
    mprisPoll.exec({
      command: [ "sh", "-lc",
        "P=$(" +
          "playerctl -a status --format '{{playerName}}|{{status}}' 2>/dev/null " +
          "| awk -F'|' '$2==\"Playing\"{print $1; exit}'" +
        "); " +
        "if [ -z \"$P\" ]; then " +
          "P=$(playerctl -l 2>/dev/null | grep -i spotify | head -n1); " +
        "fi; " +
        "if [ -z \"$P\" ]; then " +
          "P=$(playerctl -l 2>/dev/null | head -n1); " +
        "fi; " +
        "if [ -z \"$P\" ]; then exit 0; fi; " +
        "playerctl -p \"$P\" metadata --format '{{playerName}}|{{status}}|{{artist}}|{{title}}' 2>/dev/null || true"
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

  // Try multiple icon names, because theme coverage differs a lot.
  function resolveIcon(names) {
    for (let i = 0; i < names.length; i++) {
      const p = Quickshell.iconPath(names[i]);
      if (p && p.length > 0) return p;
    }
    return "";
  }

  // ---- nav items ----
  property var navItems: [
    { icons: [ "view-app-grid", "applications-all", "applications" ], tip: "Apps", cmd: "rofi -show drun" },
    { icons: [ "system-search", "edit-find", "search" ], tip: "Search", cmd: "rofi -show drun" },
    // Browser -> zen-browser
    { icons: [ "zen-browser", "zen", "firefox", "internet-web-browser" ], tip: "Browser",
      cmd: "command -v zen-browser >/dev/null && zen-browser || command -v zen >/dev/null && zen || zen-browser"
    },
    { icons: [ "utilities-terminal", "terminal", "org.gnome.Terminal" ], tip: "Terminal", cmd: "ghostty" },
    { icons: [ "system-file-manager", "folder", "org.gnome.Nautilus" ], tip: "Files", cmd: "nautilus" }
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
    property var iconNames: []
    property string fallbackText: ""
    property bool active: false
    property bool small: false
    property color textColor: sidebar.text
    signal clicked()

    width: small ? 38 : 40
    height: small ? 38 : 40

    property bool hovered: false
    property bool pressed: false
    property string iconPath: resolveIcon(iconNames)

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
        source: root.iconPath
        visible: source !== ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: 0.95
      }

      Text {
        anchors.centerIn: parent
        visible: root.iconPath === ""
        text: root.fallbackText && root.fallbackText.length > 0 ? root.fallbackText : "?"
        color: root.textColor
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

    // Top menu button (instead of "A")
    ClickButton {
      Layout.alignment: Qt.AlignHCenter
      tip: "Menu"
      iconNames: [ "open-menu-symbolic", "open-menu", "application-menu", "view-more" ]
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
          iconNames: sidebar.navItems[index].icons
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

    // Quick controls (launch tools)
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      ClickButton {
        small: true
        tip: "WiFi (nm-applet)"
        iconNames: [ "network-wireless", "networkmanager", "nm-device-wireless" ]
        fallbackText: "W"
        onClicked: sidebar.sh("nm-applet & disown")
      }

      ClickButton {
        small: true
        tip: "Bluetooth (blueman)"
        iconNames: [ "bluetooth", "blueman", "preferences-system-bluetooth" ]
        fallbackText: "B"
        onClicked: sidebar.sh("blueman-manager & disown")
      }

      ClickButton {
        small: true
        tip: "Sound (pavucontrol)"
        iconNames: [ "audio-volume-high", "multimedia-volume-control", "pavucontrol" ]
        fallbackText: "S"
        onClicked: sidebar.sh("pavucontrol & disown")
      }

      ClickButton {
        small: true
        tip: "Power (wlogout)"
        iconNames: [ "system-shutdown", "shutdown", "system-log-out" ]
        fallbackText: "⏻"
        textColor: sidebar.danger
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

    // Mini player: ALWAYS visible
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
            iconNames: [ "media-skip-backward", "go-previous" ]
            fallbackText: "⟨"
            onClicked: sidebar.mpris("previous")
          }

          ClickButton {
            small: true
            tip: sidebar.playing ? "Pause" : "Play"
            iconNames: sidebar.playing
              ? [ "media-playback-pause", "media-pause" ]
              : [ "media-playback-start", "media-playback-play", "media-play" ]
            fallbackText: sidebar.playing ? "||" : "▶"
            onClicked: sidebar.mpris("play-pause")
          }

          ClickButton {
            small: true
            tip: "Next"
            iconNames: [ "media-skip-forward", "go-next" ]
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
