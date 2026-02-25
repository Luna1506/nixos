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

  // --- dark grey theme (less blue) ---
  property color bg: "#101010"
  property color panel: "#151515"
  property color border: "#2a2a2a"
  property color text: "#eeeeee"
  property color subtext: "#a7a7a7"
  property color accent: "#bfbfbf"   // neutral highlight instead of purple/blue
  property color ok: "#dcdcdc"
  property color warn: "#ffffff"     // power should be white

  property int activeIndex: 0

  // --- processes ---
  Process { id: runner }
  Process { id: nmproc }
  Process { id: btproc }

  property bool wifiOn: false
  property int wifiStrength: 0
  property string wifiName: ""
  property bool btOn: false

  // IMPORTANT: Process.exec uses { command: ["sh","-lc", "..."] }, not "arguments"
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

  Timer {
    interval: 2500
    running: true
    repeat: true
    onTriggered: {
      refreshWifi()
      refreshWifiDetails()
      refreshBt()
    }
  }

  Connections {
    target: nmproc
    function onFinished(exitCode, stdout, stderr) {
      const out = String(stdout || "").trim();

      // nmcli -t -f WIFI g -> enabled/disabled
      if (out === "enabled" || out === "disabled") {
        sidebar.wifiOn = (out === "enabled");
        return;
      }

      // "SSID:SIGNAL"
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

  function iconOrEmpty(name) {
    const p = Quickshell.iconPath(name);
    return p ? p : "";
  }

  property var items: [
    { icon: "view-app-grid", tip: "Apps", cmd: "rofi -show drun" },
    { icon: "system-search", tip: "Search", cmd: "rofi -show drun" },
    { icon: "internet-web-browser", tip: "Browser", cmd: "firefox" },
    { icon: "utilities-terminal", tip: "Terminal", cmd: "ghostty" },
    { icon: "system-file-manager", tip: "Files", cmd: "nautilus" },
    { icon: "preferences-system", tip: "Settings", cmd: "" },
    { icon: "view-grid", tip: "Overview", cmd: "" }
  ]

  // --- PANEL BODY (right side rounded, left side square) ---
  Item {
    id: body
    anchors.fill: parent

    Rectangle {
      id: roundedBg
      anchors.fill: parent
      radius: 18
      color: sidebar.panel
      border.color: sidebar.border
      border.width: 1
    }

    // square-off left side
    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 18
      color: sidebar.panel
    }

    // left border line
    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 1
      color: sidebar.border
    }
  }

  // click mask: only the body is clickable
  mask: Region { item: body }  // controls what is clickable :contentReference[oaicite:1]{index=1}

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 10

    // top circle "A"
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

    // buttons
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      Repeater {
        model: sidebar.items.length
        delegate: Item {
          required property int index
          width: 40; height: 40

          property var data: sidebar.items[index]
          property bool hovered: false
          property bool active: sidebar.activeIndex === index

          Rectangle {
            anchors.fill: parent
            radius: 16
            color: active ? sidebar.accent : sidebar.bg
            border.color: active ? sidebar.accent : sidebar.border
            border.width: 1
            opacity: hovered ? 1.0 : 0.95
          }

          Item {
            anchors.centerIn: parent
            width: 20; height: 20

            Image {
              anchors.fill: parent
              source: sidebar.iconOrEmpty(data.icon)
              visible: source !== ""
              fillMode: Image.PreserveAspectFit
              smooth: true
              opacity: 0.95
            }

            Text {
              anchors.centerIn: parent
              visible: sidebar.iconOrEmpty(data.icon) === ""
              text: (data.tip && data.tip.length > 0) ? data.tip[0].toUpperCase() : "?"
              color: sidebar.text
              font.pixelSize: 11
              font.weight: 800
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onEntered: hovered = true
            onExited: hovered = false
            onClicked: {
              sidebar.activeIndex = index

              if (data.tip === "Overview") {
                Hyprland.dispatch("togglespecialworkspace overview")
                return
              }

              if (data.cmd && data.cmd.length > 0) sidebar.sh(data.cmd)
            }
          }

          ToolTip.visible: hovered
          ToolTip.text: data.tip
          ToolTip.delay: 350
        }
      }
    }

    Item { Layout.fillHeight: true }

    // wifi + bt
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      Item {
        width: 40; height: 40
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 16
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: hovered ? 1.0 : 0.95
        }

        Text {
          anchors.centerIn: parent
          text: sidebar.wifiOn ? "📶" : "⨯"
          color: sidebar.wifiOn ? sidebar.text : sidebar.subtext
          font.pixelSize: 15
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          onEntered: parent.hovered = true
          onExited: parent.hovered = false
          onClicked: sidebar.sh("nmcli r wifi " + (sidebar.wifiOn ? "off" : "on"))
        }
      }

      Item {
        width: 40; height: 40
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 16
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: hovered ? 1.0 : 0.95
        }

        Text {
          anchors.centerIn: parent
          text: "ᛒ"
          color: sidebar.btOn ? sidebar.text : sidebar.subtext
          font.pixelSize: 17
          font.weight: 800
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          onEntered: parent.hovered = true
          onExited: parent.hovered = false
          onClicked: sidebar.sh("bluetoothctl power " + (sidebar.btOn ? "off" : "on"))
        }
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

          color: isActive ? sidebar.text : sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: isActive ? 1.0 : 0.45

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: Hyprland.dispatch("workspace " + ws)
          }
        }
      }
    }

    // bottom: label + time + power
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      Item {
        width: 40
        height: 105
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
        height: 100

        Column {
          anchors.centerIn: parent
          spacing: 5

          Text {
            text: Qt.formatDateTime(new Date(), "dd")
            color: sidebar.text
            font.pixelSize: 13
            width: 40
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            text: Qt.formatDateTime(new Date(), "MM")
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
            text: Qt.formatDateTime(new Date(), "HH")
            color: sidebar.text
            font.pixelSize: 12
            width: 40
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            text: Qt.formatDateTime(new Date(), "mm")
            color: sidebar.subtext
            font.pixelSize: 10
            width: 40
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      Item {
        width: 40; height: 40
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 16
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: hovered ? 1.0 : 0.95
        }

        Text {
          anchors.centerIn: parent
          text: "⏻"
          color: sidebar.warn
          font.pixelSize: 17
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          onEntered: parent.hovered = true
          onExited: parent.hovered = false
          onClicked: sidebar.sh('printf "lock\\nlogout\\nreboot\\npoweroff\\n" | rofi -dmenu -p Power | xargs -r -I{} sh -lc \'case "{}" in lock) hyprlock ;; logout) hyprctl dispatch exit ;; reboot) systemctl reboot ;; poweroff) systemctl poweroff ;; esac\'')
        }
      }
    }
  }
}
