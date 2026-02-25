import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
  id: sidebar
  anchors { top: true; bottom: true; left: true }
  implicitWidth: 64
  color: "transparent"

  // --- style ---
  property color bg: "#121318"
  property color panel: "#171923"
  property color border: "#2a2f3a"
  property color text: "#e7e9ef"
  property color subtext: "#9aa3b2"
  property color accent: "#8b5cf6"     // purple
  property color accent2: "#22c55e"    // green
  property color warn: "#f59e0b"       // amber

  // Active button highlight
  property int activeIndex: 0

  // --- processes (status) ---
  Process { id: nmcli }
  Process { id: btctl }
  Process { id: runner }

  property bool wifiOn: false
  property int wifiStrength: 0
  property string wifiName: ""

  property bool btOn: false

  function exec(cmd) {
    if (!cmd || cmd.length === 0) return;
    runner.exec({ arguments: [ "sh", "-lc", cmd ] });
  }

  function refreshWifi() {
    // WiFi enabled?
    nmcli.exec({ arguments: [ "sh", "-lc", "nmcli -t -f WIFI g 2>/dev/null || true" ] })
  }

  function refreshWifi2() {
    // Active WiFi: SSID + signal
    nmcli.exec({ arguments: [ "sh", "-lc", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | awk -F: '$1==\"yes\"{print $2\":\"$3; exit}' 2>/dev/null || true" ] })
  }

  function refreshBt() {
    btctl.exec({ arguments: [ "sh", "-lc", "bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}' || true" ] })
  }

  Timer {
    interval: 2500
    running: true
    repeat: true
    onTriggered: {
      refreshWifi()
      refreshWifi2()
      refreshBt()
    }
  }

  Connections {
    target: nmcli
    function onFinished(exitCode, stdout, stderr) {
      // We called two different commands with same Process; detect by content
      const out = String(stdout || "").trim();

      if (out === "enabled" || out === "disabled") {
        sidebar.wifiOn = (out === "enabled");
        return;
      }

      // expected "SSID:SIGNAL"
      if (out.includes(":")) {
        const parts = out.split(":");
        sidebar.wifiName = parts[0] || "";
        const sig = parseInt(parts[1] || "0", 10);
        sidebar.wifiStrength = isNaN(sig) ? 0 : sig;
        return;
      }

      // fallback
      if (out.length === 0) {
        sidebar.wifiName = "";
        sidebar.wifiStrength = 0;
      }
    }
  }

  Connections {
    target: btctl
    function onFinished(exitCode, stdout, stderr) {
      const out = String(stdout || "").trim().toLowerCase();
      sidebar.btOn = (out === "yes" || out === "true" || out === "on");
    }
  }

  // --- button model ---
  property var items: [
    { icon: "view-app-grid", tip: "Apps", cmd: "rofi -show drun" },
    { icon: "system-search", tip: "Search", cmd: "rofi -show drun" },
    { icon: "internet-web-browser", tip: "Browser", cmd: "firefox" },
    { icon: "utilities-terminal", tip: "Terminal", cmd: "ghostty" },
    { icon: "system-file-manager", tip: "Files", cmd: "nautilus" },
    { icon: "preferences-system", tip: "Settings", cmd: "" },
    { icon: "view-grid", tip: "Overview", cmd: "qs ipc call overview toggle || true" }
  ]

  // --- background panel ---
  Rectangle {
    anchors.fill: parent
    radius: 22
    color: sidebar.panel
    border.color: sidebar.border
    border.width: 1
  }

  // --- content layout ---
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 10
    spacing: 12

    // top "avatar" circle
    Item {
      Layout.alignment: Qt.AlignHCenter
      width: 46
      height: 46

      Rectangle {
        anchors.fill: parent
        radius: 23
        color: sidebar.bg
        border.color: sidebar.border
        border.width: 1
      }

      Text {
        anchors.centerIn: parent
        text: "A"
        color: sidebar.text
        font.pixelSize: 16
        font.weight: 700
        opacity: 0.95
      }
    }

    // buttons stack
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 10

      Repeater {
        model: sidebar.items.length

        delegate: Item {
          required property int index
          width: 46
          height: 46

          property var data: sidebar.items[index]
          property bool hovered: false
          property bool active: sidebar.activeIndex === index

          Rectangle {
            anchors.fill: parent
            radius: 18
            color: active ? sidebar.accent : sidebar.bg
            border.color: active ? sidebar.accent : sidebar.border
            border.width: 1
            opacity: hovered ? 1.0 : 0.95

            Behavior on opacity { NumberAnimation { duration: 120 } }
          }

          // icon (robust fallback)
          Item {
            anchors.centerIn: parent
            width: 22
            height: 22

            Image {
              anchors.fill: parent
              source: Quickshell.iconPath(data.icon)
              fillMode: Image.PreserveAspectFit
              smooth: true
              visible: source !== ""
              opacity: active ? 1.0 : 0.95
            }

            Text {
              anchors.centerIn: parent
              visible: Quickshell.iconPath(data.icon) === ""
              text: data.tip && data.tip.length > 0 ? data.tip[0].toUpperCase() : "?"
              color: sidebar.text
              font.pixelSize: 12
              font.weight: 700
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: hovered = true
            onExited: hovered = false
            onClicked: {
              sidebar.activeIndex = index
              if (data.cmd && data.cmd.length > 0) sidebar.exec(data.cmd)
            }
          }

          ToolTip.visible: hovered
          ToolTip.text: data.tip
          ToolTip.delay: 350
        }
      }
    }

    // spacer
    Item { Layout.fillHeight: true }

    // status section: WiFi + BT
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 10

      // WiFi pill
      Item {
        width: 46; height: 46
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 18
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: hovered ? 1.0 : 0.95
        }

        Text {
          anchors.centerIn: parent
          // simple glyph fallback, no icon-theme dependency
          text: sidebar.wifiOn ? "📶" : "⨯"
          color: sidebar.wifiOn ? sidebar.accent2 : sidebar.subtext
          font.pixelSize: 16
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: parent.hovered = true
          onExited: parent.hovered = false
          onClicked: sidebar.exec("nmcli r wifi " + (sidebar.wifiOn ? "off" : "on"))
        }

        ToolTip.visible: hovered
        ToolTip.text: sidebar.wifiOn
          ? ("WiFi: " + (sidebar.wifiName || "connected") + " (" + sidebar.wifiStrength + "%)")
          : "WiFi: off"
      }

      // Bluetooth pill
      Item {
        width: 46; height: 46
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 18
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: hovered ? 1.0 : 0.95
        }

        Text {
          anchors.centerIn: parent
          text: "ᛒ" // cheap BT-ish rune; works everywhere
          color: sidebar.btOn ? sidebar.accent2 : sidebar.subtext
          font.pixelSize: 18
          font.weight: 700
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: parent.hovered = true
          onExited: parent.hovered = false
          onClicked: sidebar.exec("bluetoothctl power " + (sidebar.btOn ? "off" : "on"))
        }

        ToolTip.visible: hovered
        ToolTip.text: sidebar.btOn ? "Bluetooth: on" : "Bluetooth: off"
      }
    }

    // workspaces: dots (1..10)
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 8

      Repeater {
        model: 10
        delegate: Rectangle {
          required property int index
          width: 10; height: 10
          radius: 5

          property int ws: index + 1
          property bool isActive: Hyprland.focusedWorkspace && (Hyprland.focusedWorkspace.id === ws)

          color: isActive ? sidebar.accent : sidebar.bg
          border.color: isActive ? sidebar.accent : sidebar.border
          border.width: 1
          opacity: isActive ? 1.0 : 0.55

          MouseArea {
            anchors.fill: parent
            onClicked: Hyprland.dispatch("workspace " + ws)
          }
        }
      }
    }

    // bottom: Desktop label + date/time + power
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 10

      Item {
        width: 46
        height: 130

        Text {
          anchors.centerIn: parent
          rotation: 90
          text: "Desktop"
          color: sidebar.subtext
          font.pixelSize: 12
          font.weight: 600
          letterSpacing: 1
        }
      }

      Item {
        width: 46
        height: 120

        Column {
          anchors.centerIn: parent
          spacing: 6

          Text {
            text: Qt.formatDateTime(new Date(), "dd")
            color: sidebar.text
            font.pixelSize: 14
            width: 46
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.95
          }
          Text {
            text: Qt.formatDateTime(new Date(), "MM")
            color: sidebar.subtext
            font.pixelSize: 11
            width: 46
            horizontalAlignment: Text.AlignHCenter
          }

          Rectangle {
            width: 18; height: 1
            radius: 1
            color: sidebar.border
            anchors.horizontalCenter: parent.horizontalCenter
          }

          Text {
            text: Qt.formatDateTime(new Date(), "HH")
            color: sidebar.text
            font.pixelSize: 13
            width: 46
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            text: Qt.formatDateTime(new Date(), "mm")
            color: sidebar.subtext
            font.pixelSize: 11
            width: 46
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      // power
      Item {
        width: 46; height: 46
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 18
          color: sidebar.bg
          border.color: sidebar.border
          border.width: 1
          opacity: hovered ? 1.0 : 0.95
        }

        Text {
          anchors.centerIn: parent
          text: "⏻"
          color: sidebar.warn
          font.pixelSize: 18
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: parent.hovered = true
          onExited: parent.hovered = false
          onClicked: sidebar.exec('printf "lock\\nlogout\\nreboot\\npoweroff\\n" | rofi -dmenu -p Power | xargs -r -I{} sh -lc \'case "{}" in lock) hyprlock ;; logout) hyprctl dispatch exit ;; reboot) systemctl reboot ;; poweroff) systemctl poweroff ;; esac\'')
        }
      }
    }
  }
}
