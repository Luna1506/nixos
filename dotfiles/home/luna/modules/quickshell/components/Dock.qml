import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
  id: dock
  anchors { bottom: true; left: true; right: true }
  implicitHeight: 86

  Item {
    anchors.fill: parent

    GlassRect {
      id: bg
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 10
      width: Math.min(parent.width - 40, 620)
      height: 64
      radius: 18
      opacity: 0.70
    }

    RowLayout {
      anchors.fill: bg
      anchors.margins: 10
      spacing: 10

      IconButton { iconName: "firefox"; label: "Firefox"; command: "firefox" }
      IconButton { iconName: "org.gnome.Terminal"; label: "Terminal"; command: "ghostty" }
      IconButton { iconName: "code"; label: "Code"; command: "code" }
      IconButton { iconName: "discord"; label: "Discord"; command: "vesktop" }

      Item { Layout.fillWidth: true }

      IconButton {
        iconName: "system-search"
        label: "Search"
        command: "rofi -show drun"
      }
    }
  }
}
