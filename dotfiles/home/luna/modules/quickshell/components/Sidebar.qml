import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
  id: sidebar

  // PanelWindow anchors are bools (shell anchors)
  anchors { top: true; bottom: true; left: true }

  // thinner
  implicitWidth: 52

  // keep transparent; panel draws its own background
  color: "transparent"

  // make it focusable just in case (keyboard focus); not required for clicks but harmless
  focusable: false

  // --- theme (dark) ---
  property color bg: "#0f1117"
  property color panel: "#121725"
  property color border: "#222a3a"
  property color text: "#e7e9ef"
  property color subtext: "#9aa3b2"
  property color accent: "#8b5cf6"
  property color ok: "#22c55e"
  property color warn: "#f59e0b"

  property int activeIndex: 0

  // --- processes ---
  Process { id: runner }
  Process { id: nmproc }
  Process { id: btproc }

  property bool wifiOn: false
  property int wifiStrength: 0
  property string wifiName: ""
  property bool btOn: false

  function sh(cmd) {
    if (!cmd || cmd.length === 0) return;
    runner.exec({ arguments: [ "sh", "-lc", cmd ] });
  }

  function refreshWifi() {
    nmproc.exec({ arguments: [ "sh", "-lc", "nmcli -t -f WIFI g 2>/dev/null || true" ] });
  }
  function refreshWifiDetails() {
    nmproc.exec({ arguments: [ "sh", "-lc", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | awk -F: '$1==\"yes\"{print $2\":\"$3; exit}' 2>/dev/null || true" ] });
  }
  function refreshBt() {
    btproc.exec({ arguments: [ "sh", "-lc", "bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}' || true" ] });
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

      // first command: nmcli -t -f WIFI g  -> "enabled"/"disabled"
      if (out === "enabled" || out === "disabled") {
        sidebar.wifiOn = (out === "enabled");
        return;
      }

      // second command returns "SSID:SIGNAL"
      if (out.includes(":")) {
        const parts = out.split(":");
        sidebar.wifiName = parts[0] || "";
        const sig = parseInt(parts[1] || "0", 10);
        sidebar.wifiStrength = isNaN(sig) ? 0 : sig;
        return;
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

  // Sidebar items (cmd may be empty; still highlights)
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

    // We use a rounded rect and then "square off" the left side by covering it.
    Rectangle {
      id: roundedBg
      anchors.fill: parent
      radius: 18
      color: sidebar.panel
      border.color: sidebar.border
      border.width: 1
    }

    // Square-off strip on the LEFT to remove rounding on the screen-edge side
    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 18  // must be >= radius
      color: sidebar.panel
      border.color: "transparent"
    }

    // also square the border on the left edge
    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 1
      color: sidebar.border
    }
  }

  // IMPORTANT: Explicit click mask so the panel reliably receives clicks.
  // Only the body area is clickable; clicks outside pass through.
  mask: Region { item: body }  // :contentReference[oaicite:1]{index=1}

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
            opacity: hovered ? 1.0 : 0.94
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
            // make sure we actually accept the click
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
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

    // status: wifi + bt
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 9

      // wifi
      Item {
        width: 40; height: 40
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 16
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: hovered ? 1.0 : 0.94
        }

        Text {
          anchors.centerIn: parent
          text: sidebar.wifiOn ? "📶" : "⨯"
          color: sidebar.wifiOn ? sidebar.ok : sidebar.subtext
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

        ToolTip.visible: hovered
        ToolTip.text: sidebar.wifiOn
          ? ("WiFi: " + (sidebar.wifiName || "connected") + " (" + sidebar.wifiStrength + "%)")
          : "WiFi: off"
      }

      // bt
      Item {
        width: 40; height: 40
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 16
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: hovered ? 1.0 : 0.94
        }

        Text {
          anchors.centerIn: parent
          text: "ᛒ"
          color: sidebar.btOn ? sidebar.ok : sidebar.subtext
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

        ToolTip.visible: hovered
        ToolTip.text: sidebar.btOn ? "Bluetooth: on" : "Bluetooth: off"
      }
    }

    // workspaces (dots)
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

          color: isActive ? sidebar.accent : sidebar.bg
          border.color: isActive ? sidebar.accent : sidebar.border
          border.width: 1
          opacity: isActive ? 1.0 : 0.50

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
          opacity: hovered ? 1.0 : 0.94
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
