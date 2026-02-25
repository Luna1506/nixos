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

  // --- helpers ---
  Process { id: runner }
  function exec(cmd) {
    if (!cmd || cmd.length === 0) return;
    runner.exec({ arguments: [ "sh", "-lc", cmd ] });
  }

  // active button index (for highlight like screenshot)
  property int activeIndex: 7

  // button model (match the feel of the screenshot: many generic icons)
  // You can later swap icons/commands 1:1 to your liking.
  property var items: [
    { icon: "view-app-grid",     tip: "Apps",     cmd: "rofi -show drun" },
    { icon: "user-home",         tip: "Home",     cmd: "xdg-open ~" },
    { icon: "mail-unread",       tip: "Mail",     cmd: "" },
    { icon: "internet-web-browser", tip: "Browser", cmd: "firefox" },
    { icon: "folder",            tip: "Files",    cmd: "nautilus" },
    { icon: "preferences-system",tip: "Settings", cmd: "" },
    { icon: "system-search",     tip: "Search",   cmd: "rofi -show drun" },
    { icon: "view-grid",         tip: "Overview", cmd: "" },     // highlighted like in the image
    { icon: "applications-games",tip: "Games",    cmd: "" }
  ]

  // Background "pill"
  GlassRect {
    anchors.fill: parent
    radius: 22
    opacity: 0.62
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 10
    spacing: 12

    // --- Top logo "A" ---
    Item {
      Layout.alignment: Qt.AlignHCenter
      width: 44; height: 44

      Rectangle {
        anchors.centerIn: parent
        width: 40; height: 40
        radius: 16
        color: "transparent"
        border.color: "#ffffff"
        border.width: 1
        opacity: 0.18
      }

      Text {
        anchors.centerIn: parent
        text: "A"
        color: "white"
        opacity: 0.92
        font.pixelSize: 18
        font.weight: 600
      }
    }

    // --- Icon stack ---
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
          property bool active: (index === sidebar.activeIndex)
          property bool hovered: false

          Rectangle {
            anchors.fill: parent
            radius: 18
            color: active ? "#7c5cff" : "transparent"
            border.color: "#ffffff"
            border.width: 1
            opacity: active ? 0.88 : (hovered ? 0.18 : 0.10)

            Behavior on opacity { NumberAnimation { duration: 120 } }
          }

          Image {
            anchors.centerIn: parent
            width: 22
            height: 22
            source: Quickshell.iconPath(data.icon)
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: active ? 0.98 : 0.90
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: hovered = true
            onExited: hovered = false
            onClicked: {
              sidebar.activeIndex = index

              // Special-case: Overview button – toggle special workspace as placeholder
              if (data.tip === "Overview") {
                Hyprland.dispatch("togglespecialworkspace overview")
                return
              }

              if (data.cmd && data.cmd.length > 0) sidebar.exec(data.cmd)
            }
          }

          ToolTip.visible: hovered
          ToolTip.text: data.tip
          ToolTip.delay: 350
        }
      }
    }

    // --- Spacer ---
    Item { Layout.fillHeight: true }

    // --- "Desktop" section like screenshot (rotated label + monitor icon) ---
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 10

      // small monitor icon
      Item {
        width: 46; height: 46
        Rectangle {
          anchors.fill: parent
          radius: 18
          color: "transparent"
          border.color: "#ffffff"
          border.width: 1
          opacity: 0.10
        }
        Image {
          anchors.centerIn: parent
          width: 20; height: 20
          source: Quickshell.iconPath("video-display")
          opacity: 0.9
          fillMode: Image.PreserveAspectFit
          smooth: true
        }
      }

      // rotated "Desktop"
      Item {
        width: 46
        height: 140

        Text {
          anchors.centerIn: parent
          text: "Desktop"
          color: "white"
          opacity: 0.85
          font.pixelSize: 12
          rotation: 90
        }
      }
    }

    // --- Bottom cluster: date/time vertical + power ---
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 10

      // date/time vertical block
      Item {
        width: 46
        height: 140

        Column {
          anchors.centerIn: parent
          spacing: 8

          Text {
            text: Qt.formatDateTime(new Date(), "dd")
            color: "white"
            opacity: 0.9
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            width: 46
          }

          Text {
            text: Qt.formatDateTime(new Date(), "MM")
            color: "white"
            opacity: 0.75
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            width: 46
          }

          Rectangle {
            width: 18
            height: 1
            radius: 1
            color: "white"
            opacity: 0.25
            anchors.horizontalCenter: parent.horizontalCenter
          }

          Text {
            text: Qt.formatDateTime(new Date(), "hh")
            color: "white"
            opacity: 0.9
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            width: 46
          }

          Text {
            text: Qt.formatDateTime(new Date(), "mm")
            color: "white"
            opacity: 0.75
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            width: 46
          }

          Text {
            text: Qt.formatDateTime(new Date(), "AP")
            color: "white"
            opacity: 0.6
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            width: 46
          }
        }
      }

      // power button
      Item {
        width: 46; height: 46
        property bool hovered: false

        Rectangle {
          anchors.fill: parent
          radius: 18
          color: "transparent"
          border.color: "#ffffff"
          border.width: 1
          opacity: hovered ? 0.18 : 0.10
          Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        Image {
          anchors.centerIn: parent
          width: 20; height: 20
          source: Quickshell.iconPath("system-shutdown")
          opacity: 0.9
          fillMode: Image.PreserveAspectFit
          smooth: true
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: parent.hovered = true
          onExited: parent.hovered = false
          onClicked: {
            // tiny power menu
            sidebar.exec('printf "poweroff\\nreboot\\nlogout\\nlock\\n" | rofi -dmenu -p Power | xargs -r -I{} sh -lc \'case "{}" in poweroff) systemctl poweroff ;; reboot) systemctl reboot ;; logout) hyprctl dispatch exit ;; lock) hyprlock ;; esac\'')
          }
        }
      }
    }
  }
}
